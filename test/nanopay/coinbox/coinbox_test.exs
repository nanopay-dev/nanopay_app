defmodule Nanopay.CoinboxTest do
  use Nanopay.DataCase, async: true
  alias Nanopay.Coinbox
  alias Nanopay.Coinbox.{Coin, Txn}

  describe "list_coins/2" do
    setup do
      coin1 = Coin.init(0, "999", 100_000)
      coin2 = Coin.init(0, "999", 25_000) |> Map.put(:spending_txid, "0000000000000000000000000000000000000000000000000000000000000009")
      coin3 = Coin.init(0, "999", 50_000)
      {:ok, _} = Coinbox.create_coins([coin1], %Txn{txid: "0000000000000000000000000000000000000000000000000000000000000001", block: 5000, status: :pushed})
      {:ok, _} = Coinbox.create_coins([coin2], %Txn{txid: "0000000000000000000000000000000000000000000000000000000000000002", block: 5000, status: :pushed})
      {:ok, _} = Coinbox.create_coins([coin3], %Txn{txid: "0000000000000000000000000000000000000000000000000000000000000003", status: :pushed})
    end

    test "returns all Coins unless spent" do
      coins = Coinbox.list_coins(:inbox)
      assert length(coins) == 2
      assert Enum.map(coins, & &1.satoshis) |> Enum.sum() == 150_000
    end
  end


  describe "get_stats/1" do
    setup do
      # These Coins will be confirmed
      coins1 = Enum.flat_map([{5, 500}, {10, 50_000}, {15, 500_000}], fn {num, sats} ->
        Enum.map((1..num), & Coin.init(:pool, "/999/1/#{ &1 }", sats))
      end)
      |> Enum.with_index()
      |> Enum.map(fn {coin, i} -> Map.put(coin, :funding_vout, i) end)

      # These Coins will be unconfirmed
      coins2 = Enum.flat_map([{1, 500}, {1, 50_000}, {1, 500_000}], fn {num, sats} ->
        Enum.map((1..num), & Coin.init(:pool, "/999/2/#{ &1 }", sats))
      end)
      |> Enum.with_index()
      |> Enum.map(fn {coin, i} -> Map.put(coin, :funding_vout, i) end)

      # These Coins will be in channel 2
      coins3 = Enum.flat_map([{1, 500}, {1, 50_000}, {1, 500_000}], fn {num, sats} ->
        Enum.map((1..num), & Coin.init(:pool, "/999/2/#{ &1 }", sats))
      end)
      |> Enum.with_index()
      |> Enum.map(fn {coin, i} -> Map.put(coin, :funding_vout, i) end)

      # These Coins will be spent
      coins4 = Enum.flat_map([{1, 500}, {1, 50_000}, {1, 500_000}], fn {num, sats} ->
        (1..num)
        |> Enum.map(& Coin.init(:pool, "/999/3/#{ &1 }", sats))
        |> Enum.map(& Map.put(&1, :spending_txid, "0000000000000000000000000000000000000000000000000000000000000009"))
      end)
      |> Enum.with_index()
      |> Enum.map(fn {coin, i} -> Map.put(coin, :funding_vout, i) end)

      {:ok, _} = Coinbox.create_coins(coins1, %Txn{txid: "0000000000000000000000000000000000000000000000000000000000000001", block: 5000})
      {:ok, _} = Coinbox.create_coins(coins2, %Txn{txid: "0000000000000000000000000000000000000000000000000000000000000002"})
      {:ok, _} = Coinbox.create_coins(coins3, %Txn{txid: "0000000000000000000000000000000000000000000000000000000000000003", block: 5000})
      {:ok, _} = Coinbox.create_coins(coins4, %Txn{txid: "0000000000000000000000000000000000000000000000000000000000000004", block: 5000})
      :ok
    end

    test "returns stats object for pool channel" do
      stats = Coinbox.get_stats(:pool)

      # Confirmed
      assert %{num: 6, sum: 3000} = Enum.find(stats, & &1.c == true and &1.size == 500)
      assert %{num: 11, sum: 550_000} = Enum.find(stats, & &1.c == true and &1.size == 50_000)
      assert %{num: 16, sum: 8_000_000} = Enum.find(stats, & &1.c == true and &1.size == 500_000)

      # Unconfirmed
      assert %{num: 1, sum: 500} = Enum.find(stats, & &1.c == false and &1.size == 500)
      assert %{num: 1, sum: 50_000} = Enum.find(stats, & &1.c == false and &1.size == 50_000)
      assert %{num: 1, sum: 500_000} = Enum.find(stats, & &1.c == false and &1.size == 500_000)
    end
  end

end
