defmodule Nanopay.Coinbox.Manager do
  @moduledoc """
  TODO

  Needs refactor and alignment with Coinbox
  """
  alias Nanopay.Coinbox
  alias Nanopay.Coinbox.{Coin, Txn, Unlocker}
  alias BSV.{Script, TxBuilder, VarInt}
  alias BSV.Contract.Raw

  @typedoc "TODO"
  @type ratio_list() :: list({non_neg_integer(), float()})

  @typedoc "TODO"
  @type split_list() :: list({non_neg_integer(), non_neg_integer()})

  @max_inputs 500
  @max_outputs 2_500
  @sats_per_byte 0.5

  @p2pkh_txin_size 144
  @p2pkh_txout_size 34

  @ratios [
    {10_000, 0.1},
    {100_000, 0.2},
    {1_000_000, 0.2},
    {10_000_000, 0.5}
  ]

  @doc """
  Returns the ratio list.
  """
  @spec ratios() :: ratio_list()
  def ratios(), do: @ratios

  @doc """
  Returns the denominations list.
  """
  @spec denominations() :: list(non_neg_integer())
  def denominations(), do: Enum.map(@ratios, & elem(&1, 0))

  @doc """
  TODO
  """
  @spec build_funded_txn(list(Coin.t()), list(Coin.t())) :: Txn.t()
  def build_funded_txn(inputs, outputs)
    when is_list(inputs) and is_list(outputs)
  do
    builder = Enum.reduce(inputs, %TxBuilder{}, &unlock_coin/2)
    builder = Enum.reduce(outputs, builder, &lock_coin/2)

    Txn.from_bsv_tx_builder(builder)
  end

  # TODO
  defp lock_coin(coin, builder) do
    script = Script.from_binary!(coin.script, encoding: :hex)
    contract = Raw.lock(coin.satoshis, %{script: script})

    TxBuilder.add_output(builder, contract)
  end

  # TODO
  defp unlock_coin(coin, builder) do
    contract = coin
    |> Coin.to_bsv_utxo()
    |> Unlocker.unlock(%{coin: coin})

    TxBuilder.add_input(builder, contract)
  end

  @doc """
  TODO
  """
  @spec spend_to(integer() | :all, String.t()) ::
    {:ok, term()} |
    {:error, term()} |
    {:error, Ecto.Multi.name(), any(), any()}
  def spend_to(:all, script) do
    coin = %Coin{script: script}
    {_, funding_coins} = Coinbox.lock_all_coins(:all, limit: @max_inputs)

    in_sum = Enum.reduce(funding_coins, 0, & &2 + &1.satoshis)
    fee = ceil(calc_tx_size(funding_coins, [coin]) * @sats_per_byte)
    coin = Map.put(coin, :satoshis, in_sum - fee)
    txn = build_funded_txn(funding_coins, [coin])
    Coinbox.create_coins([], {Map.put(txn, :status, :queued), funding_coins})
  end

  def spend_to(satoshis, script) when is_integer(satoshis) do
    coin = %Coin{satoshis: satoshis, script: script}
    sats_with_fee = satoshis + with_fee_buffer([coin])
    {_, funding_coins} = Coinbox.lock_pool_coins(sats_with_fee)

    case ensure_sufficient_fee([coin], funding_coins) do
      [] ->
        Coinbox.unlock_coins(funding_coins)
        {:error, :cannot_fund_tx}

      coins ->
        txn = build_funded_txn(funding_coins, coins)
        coins
        |> List.delete(coin)
        |> Coinbox.create_coins({Map.put(txn, :status, :queued), funding_coins})
    end
  end

  @doc """
  TODO
  """
  @spec split_coins(list(Coin.t()) | :all) ::
    {:ok, term()} |
    {:error, term()} |
    {:error, Multi.name(), any(), any()}
  def split_coins(:all) do
    {_, funding_coins} = Coinbox.lock_all_coins(:inbox)
    split_coins(funding_coins)
  end

  def split_coins([]), do: {:ok, nil}

  def split_coins(funding_coins) do
    coins = funding_coins
    |> Enum.reduce(0, & &2 + &1.satoshis)
    |> satoshis_to_coins()
    |> ensure_sufficient_fee(funding_coins)

    case coins do
      [] ->
        Coinbox.unlock_coins(funding_coins)
        {:ok, nil}

      coins ->
        txn = build_funded_txn(funding_coins, coins)
        coins
        |> Coinbox.create_coins({Map.put(txn, :status, :queued), funding_coins})
    end
  end

  @doc """
  Splits the given number of satoshis in a flat list of Coins.
  """
  @spec satoshis_to_coins(non_neg_integer()) :: list(Coin.t())
  def satoshis_to_coins(satoshis) do
    # Get stats pool
    stats = Coinbox.get_stats(:pool)
    sum = stats
    |> Enum.map(& &1.sum)
    |> Enum.sum()
    total_satoshis = satoshis + sum

    total_satoshis
    |> split_satoshis()
    |> deduct_existing(stats)
    |> limit_splits()
    |> build_coins(base_path())
  end

  @doc """
  Splits the given number of satoshis according to the modules ratio.
  """
  @spec split_satoshis(non_neg_integer()) :: split_list()
  def split_satoshis(satoshis) do
    Enum.map @ratios, fn {sats, ratio} ->
      {sats, floor(satoshis * ratio / sats)}
    end
  end

  # Deducts existing splits from the split list
  defp deduct_existing(splits, stats) do
    Enum.map splits, fn {sats, num} ->
      existing = stats
      |> Enum.filter(& &1.size == sats)
      |> Enum.map(& &1.num)
      |> Enum.sum()

      {sats, num - existing}
    end
  end

  # Ensure splits dont exceed max outputs setting
  defp limit_splits(splits), do: limit_splits(splits, [], 0)

  defp limit_splits([], acc, _count), do: acc

  defp limit_splits(_splits, [{sats, num} | acc], count)
    when count > @max_outputs,
    do: [{sats, num-(count-@max_outputs)} | acc]

  defp limit_splits([{sats, num} | splits], acc, count),
    do: limit_splits(splits, [{sats, num} | acc], count + num)

  # Iterrates over the split list and builds a list of Coins
  defp build_coins(splits, base_path, coins \\ [])

  defp build_coins([], _base_path, coins), do: coins

  defp build_coins([{_sats, num} | splits], base_path, coins)
    when num <= 0,
    do: build_coins(splits, base_path, coins)

  defp build_coins([{sats, num} | splits], base_path, coins) do
    path = "#{ base_path }/#{ sats }"
    coins = Enum.reduce((num..1), coins, fn i, coins ->
      coin = Coin.init(:pool, "#{ path }/#{ i }", sats)
      [coin | coins]
    end)

    build_coins(splits, base_path, coins)
  end

  # Build base derivation path from datetime
  defp base_path() do
    ts = DateTime.utc_now()
    |> DateTime.to_unix()
    |> to_string()
    "/mgr/#{ts}"
  end

  # Calculates tx size and ensures suffcient fee is present
  # If possible, adds a change output
  # If necessary, drops coins
  defp ensure_sufficient_fee([], _funding_coins), do: []
  defp ensure_sufficient_fee(coins, funding_coins) do
    in_sum = Enum.reduce(funding_coins, 0, & &2 + &1.satoshis)
    out_sum = Enum.reduce(coins, 0, & &2 + &1.satoshis)
    fee = ceil(calc_tx_size(funding_coins, coins) * @sats_per_byte)

    case in_sum - (out_sum + fee) do
      diff when diff > @p2pkh_txout_size ->
        [Coin.init_change(diff - @p2pkh_txout_size) | coins]
      diff when diff >= 0 ->
        coins
      diff ->
        coins
        |> drop_coins(diff)
        |> ensure_sufficient_fee(funding_coins)
    end
  end

  # TODO
  defp drop_coins(coins, diff) when diff >= 0, do: coins
  defp drop_coins([top | coins], diff),
    do: drop_coins(coins, diff + top.satoshis)

  # TODO
  defp calc_tx_size(funding_coins, coins) do
    Enum.sum([
      8,                                                        # version + locktime
      length(funding_coins) |> VarInt.encode() |> byte_size(),  # txin num
      length(coins) |> VarInt.encode() |> byte_size(),          # txout num
      Enum.reduce(funding_coins, 0, & &2 + txin_size(&1)),      # txins
      Enum.reduce(coins, 0, & &2 + txout_size(&1))              # txouts
    ])
  end

  # TODO
  defp with_fee_buffer(coins) do
    Enum.sum([
      8,                                                        # version + locktime
      VarInt.encode(5) |> byte_size(),                          # txin num
      length(coins) |> VarInt.encode() |> byte_size(),          # txout num
      Enum.reduce(1..5, 0, fn _, sum -> sum + @p2pkh_txin_size end),  # txins
      Enum.reduce(coins, 0, & &2 + txout_size(&1))              # txouts
    ])
    |> Kernel.*(@sats_per_byte)
    |> ceil()
  end

  # TODO
  defp txin_size(_coin), do: @p2pkh_txin_size

  # TODO
  defp txout_size(_coin), do: @p2pkh_txout_size

end
