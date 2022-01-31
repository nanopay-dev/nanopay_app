defmodule Nanopay.Coinbox.CoinTest do
  use Nanopay.DataCase
  alias Nanopay.Coinbox.Coin

  @valid_coin_params %{
    channel: :inbox,
    path: "/test/0",
    satoshis: 10000
  }

  describe "changeset/2" do
    test "changes are valid with valid params" do
      changes = Coin.changeset(%Coin{}, @valid_coin_params)
      assert changes.valid?
    end

    test "changes are invalid with no required fields" do
      changes = Coin.changeset(%Coin{}, %{})
      refute changes.valid?
      assert %{channel: _, path: _, satoshis: _} = errors_on(changes)
    end

    test "changes are invalid with invalid channel" do
      changes = Coin.changeset(%Coin{}, %{channel: 100_000})
      refute changes.valid?
      assert %{channel: _} = errors_on(changes)
    end

    test "changes are invalid with invalid path" do
      changes = Coin.changeset(%Coin{}, %{path: "@notpath"})
      refute changes.valid?
      assert %{path: _} = errors_on(changes)
    end

    test "changes are invalid with invalid satoshis" do
      changes = Coin.changeset(%Coin{}, %{satoshis: 10})
      refute changes.valid?
      assert %{satoshis: _} = errors_on(changes)
    end
  end

  describe "init_funding/1" do
    test "returns a coin with p2pkh script" do
      assert %Coin{channel: :inbox, satoshis: 0, script: script} = Coin.init_funding()
      assert String.match?(script, ~r/^76a914[a-f0-9]{40}88ac$/)
    end
  end

  describe "init_change/1" do
    test "returns a coin with p2pkh script" do
      assert %Coin{channel: :inbox, satoshis: 5000, script: script} = Coin.init_change(5000)
      assert String.match?(script, ~r/^76a914[a-f0-9]{40}88ac$/)
    end
  end

  describe "from_funding_tx/1" do
    setup do
      coin1 = Coin.init_funding()
      coin2 = Coin.init_funding(inc: -1)
      coin3 = Coin.init_funding(inc: -5)

      tx = %BSV.Tx{}
      |> BSV.Tx.add_output(%BSV.TxOut{satoshis: 0, script: %BSV.Script{chunks: [:OP_0, :OP_RETURN, "test"]}})

      {:ok, tx: tx, coin1: coin1, coin2: coin2, coin3: coin3}
    end

    test "returns matching coins from last few days", ctx do
      tx = ctx.tx
      |> BSV.Tx.add_output(%BSV.TxOut{satoshis: 1000, script: BSV.Script.from_binary!(ctx.coin1.script, encoding: :hex)})
      |> BSV.Tx.add_output(%BSV.TxOut{satoshis: 1000, script: BSV.Script.from_binary!(ctx.coin2.script, encoding: :hex)})
      |> BSV.Tx.add_output(%BSV.TxOut{satoshis: 1000, script: BSV.Script.from_binary!(ctx.coin3.script, encoding: :hex)})

      assert {:ok, [coin1, coin2]} = Coin.from_funding_tx(tx)
      assert coin1.script == ctx.coin1.script
      assert coin2.script == ctx.coin2.script
    end

    test "returns error when no coins match", ctx do
      assert {:error, _term} = Coin.from_funding_tx(ctx.tx)
    end
  end

  describe "to_bsv_utxo/1" do
    @tag :pending
    test "returns the coin as a BSV UTXO struct"
  end

end
