defmodule NanopayWeb.P2P.Bip270ControllerTest do
  use NanopayWeb.ConnCase
  import Nanopay.PaymentsFixtures
  #alias Nanopay.Payments
  alias Nanopay.Payments.PayRequest

  describe "GET /p2p/bip270/payment/:id BIP270 style" do
    setup %{conn: conn} do
      %{
        conn: put_req_header(conn, "accept", "application/bitcoinsv-paymentrequest"),
        pay_request: pay_request_fixture()
      }
    end

    test "renders the payment request", %{
      conn: conn,
      pay_request: pay_request
    } do
      assert res = conn
      |> get(Routes.p2p_bip270_path(conn, :show, pay_request.id))
      |> json_response(200)

      assert res["network"] == "bitcoin"
      assert length(res["outputs"]) >= 1
      assert Regex.match?(~r/^http.+\/p2p\/bip270\/payment/, res["paymentUrl"])
    end
  end

  describe "GET /p2p/bip270/payment/:id BIP270-HC style" do
    setup %{conn: conn} do
      %{
        conn: put_req_header(conn, "accept", "application/json"),
        pay_request: pay_request_fixture()
      }
    end

    test "renders the payment request", %{
      conn: conn,
      pay_request: pay_request
    } do
      assert res = conn
      |> get(Routes.p2p_bip270_path(conn, :show, pay_request.id))
      |> json_response(200)

      assert res["network"] == "bitcoin-sv"
      assert length(res["outputs"]) >= 1
      assert Regex.match?(~r/^http.+\/p2p\/bip270\/payment/, res["paymentUrl"])
    end
  end

  describe "POST /p2p/bip270/payment/:id BIP270 style" do
    setup %{conn: conn} do
      #Tesla.Mock.mock fn env ->
      #  case env.url do
      #    "https://merchantapi.taal.com/mapi/tx" ->
      #      File.read!("test/mocks/mapi-push.json") |> Jason.decode! |> Tesla.Mock.json
      #  end
      #end

      conn = conn
      |> put_req_header("accept", "application/bitcoinsv-paymentack")
      |> put_req_header("content-type", "application/bitcoinsv-payment")

      pay_request = pay_request_fixture()
      coins = PayRequest.build_coins(pay_request)
      builder = Enum.reduce(coins, %BSV.TxBuilder{}, fn coin, builder ->
        script = BSV.Script.from_binary!(coin.script, encoding: :hex)
        contract = BSV.Contract.Raw.lock(coin.satoshis, %{script: script})
        BSV.TxBuilder.add_output(builder, contract)
      end)

      %{conn: conn, pay_request: pay_request, coins: coins, builder: builder}
    end

    test "renders payment ACK when a valid bip270 tx is given", %{
      conn: conn,
      pay_request: pay_request,
      builder: builder
    } do
      tx = BSV.TxBuilder.to_tx(builder)
      rawtx = BSV.Tx.to_binary(tx, encoding: :hex)

      assert %{"payment" => %{"transaction" => ^rawtx}} = conn
      |> post(Routes.p2p_bip270_path(conn, :pay, pay_request.id), %{transaction: rawtx})
      |> json_response(200)

      # Reload Pay Request
      assert %{status: :funded} = Nanopay.Repo.get!(PayRequest, pay_request.id)
    end

    test "renders payment ACK when a valid tx when extra outputs is given", %{
      conn: conn,
      pay_request: pay_request,
      builder: builder
    } do
      tx = builder
      |> BSV.TxBuilder.add_output(BSV.Contract.OpReturn.lock(0, %{data: ["HELLO WORLD!"] }))
      |> BSV.TxBuilder.to_tx()
      rawtx = BSV.Tx.to_binary(tx, encoding: :hex)

      assert %{"payment" => %{"transaction" => ^rawtx}} = conn
      |> post(Routes.p2p_bip270_path(conn, :pay, pay_request.id), %{transaction: rawtx})
      |> json_response(200)

      # Reload Pay Request
      assert %{status: :funded} = Nanopay.Repo.get!(PayRequest, pay_request.id)
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

      assert %{"error" => 1, "memo" => "Bad Request"} = conn
      |> post(Routes.p2p_bip270_path(conn, :pay, pay_request.id), %{transaction: rawtx})
      |> json_response(400)
    end

    test "renders error with invalid tx", %{
      conn: conn,
      pay_request: pay_request,
    } do
      assert %{"error" => 1, "memo" => "Bad Request"} = conn
      |> post(Routes.p2p_bip270_path(conn, :pay, pay_request.id), %{transaction: "ababababecececec"})
      |> json_response(400)
    end

    test "renders error if wrong tx", %{
      conn: conn,
      pay_request: pay_request,
    } do
      rawtx = "01000000012971e2a512999c3234b10b3a26906fb6391ab2a77c14a741fbefef45572ff20f010000006b4830450221008d61b486e016a0914a3d1c461b61b7ca75521b518c0490ae0dd800c73d9fc6880220313617cf73d8e4433dbe5da5f351155a9dd0311b2b98f91ccc204b4f49094b814121032d0d51f5480ac7a0c7078f06c6694d46a243d72c792af169ebffa814c4026b0fffffffff0263cb0100000000001976a914449606073363543094866674e86eb1ff3eb2432088ac6a1b8900000000001976a914f1b16ab6267189b67a722e882c5bb628cc07193d88ac00000000"
      assert %{"error" => 1, "memo" => "Bad Request"} = conn
      |> post(Routes.p2p_bip270_path(conn, :pay, pay_request.id), %{transaction: rawtx})
      |> json_response(400)
    end
  end

  describe "POST /p2p/bip270/payment/:id BIP270-HC style" do
    setup %{conn: conn} do
      #Tesla.Mock.mock fn env ->
      #  case env.url do
      #    "https://merchantapi.taal.com/mapi/tx" ->
      #      File.read!("test/mocks/mapi-push.json") |> Jason.decode! |> Tesla.Mock.json
      #  end
      #end

      conn = put_req_header(conn, "accept", "application/json")

      pay_request = pay_request_fixture()
      coins = PayRequest.build_coins(pay_request)
      builder = Enum.reduce(coins, %BSV.TxBuilder{}, fn coin, builder ->
        script = BSV.Script.from_binary!(coin.script, encoding: :hex)
        contract = BSV.Contract.Raw.lock(coin.satoshis, %{script: script})
        BSV.TxBuilder.add_output(builder, contract)
      end)

      %{conn: conn, pay_request: pay_request, coins: coins, builder: builder}
    end

    test "renders payment ACK when a valid bip270 tx is given", %{
      conn: conn,
      pay_request: pay_request,
      builder: builder
    } do
      tx = BSV.TxBuilder.to_tx(builder)
      rawtx = BSV.Tx.to_binary(tx, encoding: :hex)

      assert %{"success" => true} = conn
      |> post(Routes.p2p_bip270_path(conn, :pay, pay_request.id), %{transaction: rawtx})
      |> json_response(200)

      # Reload Pay Request
      assert %{status: :funded} = Nanopay.Repo.get!(PayRequest, pay_request.id)
    end

    test "renders payment ACK when a valid tx when extra outputs is given", %{
      conn: conn,
      pay_request: pay_request,
      builder: builder
    } do
      tx = builder
      |> BSV.TxBuilder.add_output(BSV.Contract.OpReturn.lock(0, %{data: ["HELLO WORLD!"] }))
      |> BSV.TxBuilder.to_tx()
      rawtx = BSV.Tx.to_binary(tx, encoding: :hex)

      assert %{"success" => true} = conn
      |> post(Routes.p2p_bip270_path(conn, :pay, pay_request.id), %{transaction: rawtx})
      |> json_response(200)

      # Reload Pay Request
      assert %{status: :funded} = Nanopay.Repo.get!(PayRequest, pay_request.id)
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

      assert %{"error" => 1, "memo" => "Bad Request"} = conn
      |> post(Routes.p2p_bip270_path(conn, :pay, pay_request.id), %{transaction: rawtx})
      |> json_response(400)
    end

    test "renders error with invalid tx", %{
      conn: conn,
      pay_request: pay_request,
    } do
      assert %{"error" => 1, "memo" => "Bad Request"} = conn
      |> post(Routes.p2p_bip270_path(conn, :pay, pay_request.id), %{transaction: "ababababecececec"})
      |> json_response(400)
    end

    test "renders error if wrong tx", %{
      conn: conn,
      pay_request: pay_request,
    } do
      rawtx = "01000000012971e2a512999c3234b10b3a26906fb6391ab2a77c14a741fbefef45572ff20f010000006b4830450221008d61b486e016a0914a3d1c461b61b7ca75521b518c0490ae0dd800c73d9fc6880220313617cf73d8e4433dbe5da5f351155a9dd0311b2b98f91ccc204b4f49094b814121032d0d51f5480ac7a0c7078f06c6694d46a243d72c792af169ebffa814c4026b0fffffffff0263cb0100000000001976a914449606073363543094866674e86eb1ff3eb2432088ac6a1b8900000000001976a914f1b16ab6267189b67a722e882c5bb628cc07193d88ac00000000"
      assert %{"error" => 1, "memo" => "Bad Request"} = conn
      |> post(Routes.p2p_bip270_path(conn, :pay, pay_request.id), %{transaction: rawtx})
      |> json_response(400)
    end
  end

end
