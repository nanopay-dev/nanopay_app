defmodule NanopayWeb.API.Base.FundingControllerTest do
  use NanopayWeb.ConnCase
  alias Nanopay.Coinbox.Coin

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "GET /fund" do
    test "responds with todays funding script", %{conn: conn} do
      assert %{"ok" => true, "data" => data} = conn
      |> get(Routes.base_api_funding_path(conn, :show))
      |> json_response(:ok)

      assert String.match?(data["script"],  ~r/^76a914[a-f0-9]{40}88ac$/)
    end
  end

  describe "POST /fund" do
    setup %{conn: conn} do
      tx = %BSV.Tx{}
      |> BSV.Tx.add_output(%BSV.TxOut{satoshis: 0, script: %BSV.Script{chunks: [:OP_0, :OP_RETURN, "test"]}})

      coin = Coin.init_funding()

      {:ok, conn: conn, tx: tx, coin: coin}
    end

    test "responds with the txid of an accepted tx", %{conn: conn} = ctx do
      tx = BSV.Tx.add_output( ctx.tx, %BSV.TxOut{satoshis: 10_000, script: BSV.Script.from_binary!(ctx.coin.script, encoding: :hex)})
      rawtx = BSV.Tx.to_binary(tx, encoding: :hex)

      assert %{"ok" => true, "data" => data} = conn
      |> post(Routes.base_api_funding_path(conn, :create), %{"rawtx" => rawtx})
      |> json_response(:created)

      assert data["txid"] == BSV.Tx.get_txid(tx)
    end

    test "responds with an error if the tx does not contain funding script", %{conn: conn} = ctx do
      rawtx = BSV.Tx.to_binary(ctx.tx, encoding: :hex)

      assert %{"ok" => false, "error" => error} = conn
      |> post(Routes.base_api_funding_path(conn, :create), %{"rawtx" => rawtx})
      |> json_response(400)

      assert error == "Funding output not found"
    end

    test "responds with an error if the tx is invalid", %{conn: conn} do
      assert %{"ok" => false, "error" => error} = conn
      |> post(Routes.base_api_funding_path(conn, :create), %{"rawtx" => "01010101"})
      |> json_response(400)

      assert error == "Invalid rawtx"
    end
  end

end
