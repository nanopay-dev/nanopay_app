defmodule Nanopay.Coinbox.ManagerTest do
  use Nanopay.DataCase, async: true
  alias Nanopay.Coinbox
  alias Nanopay.Coinbox.Manager
  alias Nanopay.Coinbox.{Coin, Txn}

  describe "split_coins/1" do
    test "loads and splits 1M sats funding coins" do
      # Initially the pool is empty
      assert [] = Coinbox.get_stats(:pool)

      # Create a funding tx with 2 Coins
      coin = Coin.init_funding()
      tx = %BSV.Tx{}
      |> BSV.Tx.add_output(%BSV.TxOut{satoshis: 300_000, script: BSV.Script.from_binary!(coin.script, encoding: :hex)})
      |> BSV.Tx.add_output(%BSV.TxOut{satoshis: 700_000, script: BSV.Script.from_binary!(coin.script, encoding: :hex)})

      {:ok, coins} = Coin.from_funding_tx(tx)
      {:ok, _} = Coinbox.create_coins(coins, Txn.from_bsv_tx(tx, status: :pushed))

      # Call the splitter
      assert {:ok, %{{:coin, 0} => %{id: change_id}}} = Manager.split_coins(:all)

      # Pool is now funded with unconfirmed tx
      assert stats = Coinbox.get_stats(:pool)
      assert Enum.filter(stats, & &1.c == true) |> Enum.map(& &1.num) |> Enum.sum() == 0
      assert Enum.filter(stats, & &1.c == false) |> Enum.map(& &1.num) |> Enum.sum() == 12

      # Funding coins should now consist of our change output
      assert [%{id: ^change_id}] = Coinbox.list_coins(:inbox, status: :queued)
    end

    test "loads and splits 0.333BSV funding coins" do
      # Initially the pool is empty
      assert [] = Coinbox.get_stats(:pool)

      # Create a funding tx with 2 Coins
      coin = Coin.init_funding()
      tx = %BSV.Tx{}
      |> BSV.Tx.add_output(%BSV.TxOut{satoshis: 300_000, script: BSV.Script.from_binary!(coin.script, encoding: :hex)})
      |> BSV.Tx.add_output(%BSV.TxOut{satoshis: 33_000, script: BSV.Script.from_binary!(coin.script, encoding: :hex)})

      {:ok, coins} = Coin.from_funding_tx(tx)
      {:ok, _} = Coinbox.create_coins(coins, Txn.from_bsv_tx(tx, status: :pushed))

      # Call the splitter
      assert {:ok, %{{:coin, 0} => %{id: change_id}}} = Manager.split_coins(:all)

      # Pool is now funded with unconfirmed tx
      assert stats = Coinbox.get_stats(:pool)
      assert Enum.filter(stats, & &1.c == true) |> Enum.map(& &1.num) |> Enum.sum() == 0
      assert Enum.filter(stats, & &1.c == false) |> Enum.map(& &1.num) |> Enum.sum() == 3

      # Funding coins should now consist of our change output
      assert [%{id: ^change_id}] = Coinbox.list_coins(:inbox, status: :queued)
    end
  end

  describe "satoshis_to_coins/1" do
    test "splits 1M sats according to ratio" do
      coins = Manager.satoshis_to_coins(1_000_000)

      assert length(coins) == 12
      assert Enum.filter(coins, & &1.satoshis == 100_000) |> length() == 2
      assert Enum.filter(coins, & &1.satoshis == 10_000) |> length() == 10
    end

    test "splits 0.333BSV according to ratio" do
      coins = Manager.satoshis_to_coins(333_000)

      assert length(coins) == 3
      assert Enum.filter(coins, & &1.satoshis == 10_000) |> length() == 3
    end
  end

  describe "split_satoshis/1" do
    test "splits 1BSV according to ratio" do
      res = Manager.split_satoshis(100_000_000) |> Enum.into(%{})

      assert res[10_000] == 1000
      assert res[100_000] == 200
      assert res[1_000_000] == 20
      assert res[10_000_000] == 5
    end

    test "splits 0.333BSV according to ratio" do
      res = Manager.split_satoshis(33_300_000) |> Enum.into(%{})

      assert res[10_000] == 333
      assert res[100_000] == 66
      assert res[1_000_000] == 6
      assert res[10_000_000] == 1
    end
  end

end
