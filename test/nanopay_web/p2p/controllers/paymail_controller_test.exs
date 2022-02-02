defmodule NanopayWeb.P2P.PaymailControllerTest do
  use NanopayWeb.ConnCase
  import Nanopay.PaymentsFixtures
  alias Nanopay.Payments
  alias Nanopay.Payments.PayRequest

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "GET /.well-known/bsvalias" do
    test "renders the capabilities response", %{conn: conn} do
      assert %{"bsvalias" => "1.0", "capabilities" => capabilities} = conn
      |> get(Routes.paymail_path(conn, :capabilities))
      |> json_response(200)

      assert Map.keys(capabilities) |> Enum.member?("2a40af698840")
      assert Map.keys(capabilities) |> Enum.member?("5f1323cddf31")
    end
  end


  describe "POST /p2p/paymail/:paymail/dest" do
    setup do
      pay_request = pay_request_fixture()
      {:XSV, satoshis, -8, _} = pay_request
      |> PayRequest.get_total()
      |> Money.to_integer_exp()

      %{pay_request: pay_request, satoshis: satoshis}
    end

    test "reponds with outputs for valid pay request", %{
      conn: conn,
      pay_request: %{id: id} = pay_request,
      satoshis: satoshis
    } do
      paymail = PayRequest.get_paymail(pay_request)
      assert %{"outputs" => outputs, "reference" => ^id} = conn
      |> post(Routes.p2p_paymail_path(conn, :payment_destination, paymail), %{satoshis: satoshis})
      |> json_response(200)

      assert is_list(outputs)
    end

    test "renders not found when pay request already paid", %{
      conn: conn,
      pay_request: pay_request,
      satoshis: satoshis
    } do
      {:ok, pay_request} = Payments.set_pay_request_status(pay_request, :completed)
      paymail = PayRequest.get_paymail(pay_request)
      assert "Bad Request" == conn
      |> post(Routes.p2p_paymail_path(conn, :payment_destination, paymail), %{satoshis: satoshis})
      |> json_response(:bad_request)
    end

    test "renders not found when pay request cannot be found from paymail", %{
      conn: conn
    } do
      assert "Bad Request" == conn
      |> post(Routes.p2p_paymail_path(conn, :payment_destination, "wrong@example.com"), %{satoshis: 5000})
      |> json_response(:bad_request)
    end

    test "renders error when satoshi amount incorrect", %{
      conn: conn,
      pay_request: pay_request,
    } do
      paymail = PayRequest.get_paymail(pay_request)
      assert "Bad Request" == conn
      |> post(Routes.p2p_paymail_path(conn, :payment_destination, paymail), %{satoshis: 5000})
      |> json_response(:bad_request)
    end
  end


  describe "POST /p2p/transactions" do
    setup do
#      Tesla.Mock.mock fn env ->
#        case env.url do
#          "https://merchantapi.taal.com/mapi/tx" ->
#            File.read!("test/mocks/mapi-push.json") |> Jason.decode! |> Tesla.Mock.json
#        end
#      end
      pay_request = pay_request_fixture()
      coins = PayRequest.build_coins(pay_request)
      builder = Enum.reduce(coins, %BSV.TxBuilder{}, fn coin, builder ->
        script = BSV.Script.from_binary!(coin.script, encoding: :hex)
        contract = BSV.Contract.Raw.lock(coin.satoshis, %{script: script})
        BSV.TxBuilder.add_output(builder, contract)
      end)

      %{pay_request: pay_request, coins: coins, builder: builder}
    end

    test "renders success when a valid tx is given", %{
      conn: conn,
      pay_request: pay_request,
      builder: builder
    } do
      tx = BSV.TxBuilder.to_tx(builder)
      txid = BSV.Tx.get_txid(tx)
      rawtx = BSV.Tx.to_binary(tx, encoding: :hex)
      paymail = PayRequest.get_paymail(pay_request)

      assert %{"txid" => ^txid} = conn
      |> post(Routes.p2p_paymail_path(conn, :transactions, paymail), %{hex: rawtx, reference: pay_request.id})
      |> json_response(200)

      # Reload Pay Request
      assert %{status: :funded} = Nanopay.Repo.get!(PayRequest, pay_request.id)
    end

    test "renders success when a valid tx when extra outputs is given", %{
      conn: conn,
      pay_request: pay_request,
      builder: builder
    } do
      tx = builder
      |> BSV.TxBuilder.add_output(BSV.Contract.OpReturn.lock(0, %{data: ["HELLO WORLD!"] }))
      |> BSV.TxBuilder.to_tx()
      txid = BSV.Tx.get_txid(tx)
      rawtx = BSV.Tx.to_binary(tx, encoding: :hex)
      paymail = PayRequest.get_paymail(pay_request)

      assert %{"txid" => ^txid} = conn
      |> post(Routes.p2p_paymail_path(conn, :transactions, paymail), %{hex: rawtx, reference: pay_request.id})
      |> json_response(200)

      # Reload Pay Request
      assert %{status: :funded} = Nanopay.Repo.get!(PayRequest, pay_request.id)
    end

    test "renders error when paymail and invoice id mismatch", %{
      conn: conn,
      pay_request: pay_request,
      builder: builder
    } do
      tx = BSV.TxBuilder.to_tx(builder)
      rawtx = BSV.Tx.to_binary(tx, encoding: :hex)
      paymail = PayRequest.get_paymail(pay_request)
      assert "Bad Request" == conn
      |> post(Routes.p2p_paymail_path(conn, :transactions, paymail), %{hex: rawtx, reference: "wrong-ref"})
      |> json_response(:bad_request)
    end

    test "renders error with invalid tx", %{
      conn: conn,
      pay_request: pay_request
    } do
      paymail = PayRequest.get_paymail(pay_request)
      assert "Bad Request" == conn
      |> post(Routes.p2p_paymail_path(conn, :transactions, paymail), %{hex: "ababababecececec", reference: pay_request.id})
      |> json_response(:bad_request)
    end

    test "renders error if wrong tx", %{
      conn: conn,
      pay_request: pay_request
    } do
      paymail = PayRequest.get_paymail(pay_request)
      rawtx = "01000000012971e2a512999c3234b10b3a26906fb6391ab2a77c14a741fbefef45572ff20f010000006b4830450221008d61b486e016a0914a3d1c461b61b7ca75521b518c0490ae0dd800c73d9fc6880220313617cf73d8e4433dbe5da5f351155a9dd0311b2b98f91ccc204b4f49094b814121032d0d51f5480ac7a0c7078f06c6694d46a243d72c792af169ebffa814c4026b0fffffffff0263cb0100000000001976a914449606073363543094866674e86eb1ff3eb2432088ac6a1b8900000000001976a914f1b16ab6267189b67a722e882c5bb628cc07193d88ac00000000"
      assert "Bad Request" == conn
      |> post(Routes.p2p_paymail_path(conn, :transactions, paymail), %{hex: rawtx, reference: pay_request.id})
      |> json_response(:bad_request)
    end

    test "renders error if insufficient payment is given", %{
      conn: conn,
      pay_request: pay_request,
      coins: coins
    } do
      # create a builder with 5 less sats
      builder = Enum.reduce(coins, %BSV.TxBuilder{}, fn coin, builder ->
        script = BSV.Script.from_binary!(coin.script, encoding: :hex)
        contract = BSV.Contract.Raw.lock(coin.satoshis - 5, %{script: script})
        BSV.TxBuilder.add_output(builder, contract)
      end)

      tx = BSV.TxBuilder.to_tx(builder)
      rawtx = BSV.Tx.to_binary(tx, encoding: :hex)
      paymail = PayRequest.get_paymail(pay_request)

      assert "Bad Request" == conn
      |> post(Routes.p2p_paymail_path(conn, :transactions, paymail), %{hex: rawtx, reference: pay_request.id})
      |> json_response(:bad_request)
    end
  end

end
