defmodule NanopayWeb.API.Base.FundingController do
  @moduledoc """
  TODO
  """
  use NanopayWeb, :controller
  alias Nanopay.Coinbox
  alias Nanopay.Coinbox.{Coin, Txn}
  alias BSV.{Address, Script}

  action_fallback NanopayWeb.API.FallbackController

  @doc """
  GET /fund

  Responds with a funding script.
  """
  def show(conn, _params) do
    coin = Coin.init_funding()
    %Script{chunks: [_, _, pubkeyhash, _, _]} = Script.from_binary!(coin.script, encoding: :hex)
    address = Address.to_string(%Address{pubkey_hash: pubkeyhash})
    render(conn, "show.json", address: address, script: coin.script)
  end

  @doc """
  POST /fund

  Creates new funding UTXO(s).
  """
  def create(conn, %{"rawtx" => rawtx}) do
    with {:ok, tx} <- BSV.Tx.from_binary(rawtx, encoding: :hex),
         {:ok, coins} <- Coin.from_funding_tx(tx),
         {:ok, %{txn: txn}} <- Coinbox.create_coins(coins, Txn.from_bsv_tx(tx, status: :queued))
    do
      conn
      |> put_status(:created)
      |> render("create.json", txn: txn)
    else
      {:error, :coins_not_found} -> {:error, :coins_not_found}
      {:error, _} -> {:error, :invalid_rawtx}
    end
  end

end
