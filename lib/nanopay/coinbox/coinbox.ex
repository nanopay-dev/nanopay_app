defmodule Nanopay.Coinbox do
  @moduledoc """
  Coinbox context module
  """
  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Nanopay.Repo
  alias Nanopay.MAPI
  alias Nanopay.Coinbox.{Coin, Manager, Txn, Unlocker}
  alias Nanopay.Payments.PayRequest
  alias BSV.{Script, TxBuilder, VarInt}
  alias BSV.Contract.{Raw}

  @lock_period 60
  @p2pkh_txin_size 144
  @p2pkh_txout_size 34
  @sats_per_byte 0.5

  @doc """
  Returns a list of funding Coins.
  """
  @spec list_coins(atom(), keyword()) :: list(Coin.t())
  def list_coins(channel, opts \\ []) do
    status = Keyword.get(opts, :status, :pushed)

    qry = from c in Coin,
      inner_join: t in assoc(c, :funding_tx),
      where: c.channel == ^channel
        and is_nil(c.spending_txid)
        and is_nil(c.locked_at)
        and t.status == ^status

    Repo.all(qry)
  end


  @doc """
  TODO
  """
  @spec lock_all_coins(atom(), keyword()) :: {integer(), list(Coin.t())}
  def lock_all_coins(channel, opts \\ []) when is_atom(channel) do
    qry = from c in Coin,
      select: c,
      inner_join: t in assoc(c, :funding_tx),
      where: is_nil(c.spending_txid)
        and is_nil(c.locked_at)
        and t.status == :pushed

    qry = case channel do
      :all -> qry
      _    -> where(qry, channel: ^channel)
    end

    qry = case Keyword.get(opts, :limit) do
      nil -> qry
      lmt -> limit(qry, ^lmt)
    end

    Repo.update_all(qry, set: [locked_at: DateTime.utc_now()])
  end


  @doc """
  TODO
  """
  @spec lock_pool_coins(integer()) :: {integer(), list(Coin.t())}
  def lock_pool_coins(satoshis) when is_integer(satoshis) do
    satoshis
    |> lock_pool_coins_qry()
    |> Repo.update_all([])
  end

  @doc """
  TODO
  """
  @spec lock_pool_coins_qry(integer() | Multi.changes()) :: Ecto.Queryable.t()
  def lock_pool_coins_qry(satoshis) when is_integer(satoshis) do
    set = from c in Coin,
      inner_join: t in assoc(c, :funding_tx),
      select: %{
        id: c.id,
        sum: over(sum(c.satoshis), order_by: fragment("ABS(? - ?), ? DESC, ?", c.satoshis, ^satoshis, t.block, c.id))
      },
      where: c.channel == :pool
        and is_nil(c.spending_txid)
        and is_nil(c.locked_at)
        and t.status == :pushed

    from c in Coin,
      select: c,
      join: s in subquery(set), on: s.id == c.id,
      where: s.sum - c.satoshis < ^satoshis,
      update: [
        set: [locked_at: ^DateTime.utc_now()]
      ]
  end

  def lock_pool_coins_qry(%{pay_request: %{id: id, amount: amount}}) do
    {:XSV, satoshis, -8, _} = Money.to_integer_exp(amount)

    satoshis
    |> lock_pool_coins_qry()
    |> update(set: [pay_request_id: ^id])
  end

  @doc """
  TODO
  """
  @spec list_txns_for_mapi(keyword()) :: list(Txn.t())
  def list_txns_for_mapi(opts \\ []) do
    # Get options
    max_push_attempts = Keyword.get(opts, :max_push_attempts, 3)
    max_status_attempts = Keyword.get(opts, :max_status_attempts, 20)
    retry_push_after = Keyword.get(opts, :retry_push_after, 90)
    retry_status_after = Keyword.get(opts, :retry_status_after, 300)

    push_retry_at = DateTime.utc_now() |> DateTime.add(-retry_push_after)
    status_retry_at = DateTime.utc_now() |> DateTime.add(-retry_status_after)

    query = from t in Txn,
      select: t.txid,
      where: t.status == :queued
        and t.mapi_count < ^max_push_attempts
        and (is_nil(t.prev_mapi_at) or t.prev_mapi_at < ^push_retry_at),
      or_where: t.status == :pushed
        and is_nil(t.block)
        and t.mapi_count < ^max_status_attempts
        and (is_nil(t.prev_mapi_at) or t.prev_mapi_at < ^status_retry_at)
        and t.inserted_at < ^status_retry_at

    Repo.all(query)
  end

  @doc """
  TODO
  """
  @spec get_txn(String.t) :: Txn.t()
  def get_txn(txid), do: Repo.get(Txn, txid)

  @doc """
  TODO
  """
  @spec update_txn_with_mapi_payload(Txn.t(), map()) :: {:ok, Txn.t()} | {:error, term()}
  def update_txn_with_mapi_payload(%Txn{} = txn, %{} = payload) do
    txn
    |> Txn.mapi_changeset(%{mapi_status: payload})
    |> Repo.update()
  end

  @doc """
  TODO
  """
  @spec unlock_coins(list(Coin.t) | :all) :: {integer(), nil}
  def unlock_coins(:all) do
    release_at = DateTime.add(DateTime.utc_now(), -@lock_period)

    Coin
    |> where([u], is_nil(u.spending_txid) and is_nil(u.pay_request_id) and u.locked_at < ^release_at)
    |> Repo.update_all(set: [locked_at: nil])
  end

  def unlock_coins(coins) do
    ids = Enum.map(coins, & &1.id)

    Coin
    |> where([u], u.id in ^ids)
    |> Repo.update_all(set: [locked_at: nil])
  end

  @doc """
  Creates the given list of Coins alongside the given Txn.
  """
  @spec create_coins(list(Coin.t()), Txn.t() | {Txn.t(), list(Coin.t())}) ::
    {:ok, term()} |
    {:error, term()} |
    {:error, Multi.name(), any(), any()}
  def create_coins(coins, %Txn{} = txn) do
    multi = Multi.new()

    # 1. Insert the raw txn
    multi = Multi.insert(multi, :txn, Ecto.Changeset.change(txn))

    # 2. Insert each of the Coins
    multi = coins
    |> Enum.with_index()
    |> Enum.reduce(multi, fn {coin, i}, multi ->
      Multi.insert(multi, {:coin, i}, fn %{txn: txn} ->
        params = unless is_integer(coin.funding_vout), do: %{funding_vout: i}, else: %{}
        Coin.funding_changeset(coin, Map.put(params, :funding_txid, txn.txid))
      end)
    end)

    # 3. Push txn to mapi queue
    multi = Multi.run(multi, :mapi, fn _, %{txn: txn} ->
      {MAPI.Queue.push(txn), txn.txid}
    end)

    Repo.transaction(multi)
  end

  def create_coins(coins, {%Txn{} = txn, funding_coins}) do
    multi = Multi.new()

    # 1. Insert the raw txn
    multi = Multi.insert(multi, :txn, Ecto.Changeset.change(txn))

    # 2. Insert each of the Coins
    multi = coins
    |> Enum.with_index()
    |> Enum.reduce(multi, fn {coin, i}, multi ->
      Multi.insert(multi, {:coin, i}, fn %{txn: txn} ->
        params = unless is_integer(coin.funding_vout), do: %{funding_vout: i}, else: %{}
        Coin.funding_changeset(coin, Map.put(params, :funding_txid, txn.txid))
      end)
    end)

    # 3. Update funding coins
    multi = funding_coins
    |> Enum.with_index()
    |> Enum.reduce(multi, fn {coin, i}, multi ->
      Multi.update(multi, {:spent, i}, fn %{txn: txn} ->
        Coin.spending_changeset(coin, %{spending_vout: i, spending_txid: txn.txid})
      end)
    end)

    # 4. Push txn to mapi queue
    multi = Multi.run(multi, :mapi, fn _, %{txn: txn} ->
      {MAPI.Queue.push(txn), txn.txid}
    end)

    Repo.transaction(multi)
  end

  @doc """
  TODO
  """
  @spec spend_to(PayRequest.t()) ::
    {:ok, term()} |
    {:error, term()} |
    {:error, Multi.name(), any(), any()}
  def spend_to(%PayRequest{} = pay_request) do
    Multi.new()
    |> spend_to(pay_request)
    |> Repo.transaction()
  end

  @doc """
  TODO
  """
  @spec spend_to(Multi.t(), PayRequest.t(), keyword()) :: Multi.t()
  def spend_to(multi, %PayRequest{id: id} = pay_request, opts \\ []) do
    {:XSV, satoshis, -8, _} = Money.to_integer_exp(pay_request.amount)
    satoshis_with_fee = satoshis + est_tx_fee(5, 1)

    # 1. lock pool coins                ✔
    # 2. build outputs                  ✔
    # 3. create funding txn             ✔
    # 4. insert output coins            ✔
    # 5. update funding coins           ✔
    # 6. broadcast txn                  ✔
    # 7. set pay request to funded      ✔

    multi
    # 1. lock pool coins
    |> Multi.update_all(:pool_coins, fn _changes ->
      lock_pool_coins_qry(satoshis_with_fee)
    end, [set: [pay_request_id: id]])

    # 2. build outputs
    |> Multi.run(:coins, fn _repo, %{pool_coins: {_, inputs}} ->
      coin = Coin.init(:used, pay_request.keypath, satoshis)
      in_sum = Enum.reduce(inputs, 0, & &2 + &1.satoshis)

      case in_sum - (coin.satoshis + calc_tx_fee(inputs, [coin])) do
        diff when diff >= @p2pkh_txout_size ->
          {:ok, [coin, Coin.init_change(diff - @p2pkh_txout_size)]}
        diff when diff >= 0 ->
          {:ok, [coin]}
        _diff ->
          {:error, :cannot_fund_tx}
      end
    end)

    # 3. create funding txn
    |> Multi.insert(:txn, fn %{pool_coins: {_, inputs}, coins: outputs} ->
      txn = Manager.build_funded_txn(inputs, outputs)
      Ecto.Changeset.change(txn, %{status: :pending})
    end)

    # 4. update funding coins
    |> Multi.merge(fn %{txn: txn, pool_coins: {_, coins}} ->
      coins
      |> Enum.with_index()
      |> Enum.reduce(Multi.new(), fn {coin, i}, multi ->
        changeset = Coin.spending_changeset(coin, %{spending_txid: txn.txid, spending_vout: i})
        Multi.update(multi, {:input, i}, changeset)
      end)
    end)

    # 5. insert output coins
    |> Multi.merge(fn %{txn: txn, coins: coins} ->
      coins
      |> Enum.map(& Map.put(&1, :pay_request_id, id))
      |> Enum.with_index()
      |> Enum.reduce(Multi.new(), fn {coin, i}, multi ->
        changeset = Coin.funding_changeset(coin, %{funding_txid: txn.txid, funding_vout: i})
        Multi.insert(multi, {:output, i}, changeset)
      end)
    end)

    # 6. broadcast txn
    |> Multi.run(:push_tx, fn _repo, %{txn: txn} ->
      case Keyword.get(opts, :broadcast, :push) do
        :push ->
          mapi_opts = Application.fetch_env!(:nanopay, :mapi)
          miner = case Keyword.get(mapi_opts, :miner, :taal) do
            {url, opts} -> Manic.miner(url, opts)
            url -> Manic.miner(url)
          end
          IO.inspect Base.encode16(txn.rawtx)
          case Manic.TX.push(miner, Base.encode16(txn.rawtx)) do
            {:ok, payload} ->
              update_txn_with_mapi_payload(txn, payload)
            error ->
              error
          end

        :queue ->
          Nanopay.MAPI.Queue.push(txn)

        false ->
          {:ok, nil}
      end

    end)

    # 7. set pay request to funded
    |> Multi.update(:pay_request, PayRequest.status_changeset(pay_request, :funded))
  end


  @doc """
  TODO
  """
  @spec get_stats(atom()) :: list(map())
  def get_stats(:pool) do
    Coin
    |> join(:inner, [u], t in assoc(u, :funding_tx))
    |> where([u], is_nil(u.spending_txid) and u.channel == :pool)
    |> select([u, t], %{c: not is_nil(t.block), size: u.satoshis, num: count(u.id), sum: sum(u.satoshis)})
    |> group_by([u, t], [not is_nil(t.block), u.satoshis])
    |> Repo.all()
  end

  def get_stats(channel) do
    Coin
    |> join(:inner, [u], t in assoc(u, :funding_tx))
    |> where([u], is_nil(u.spending_txid) and u.channel == ^channel)
    |> select([u, t], %{c: not is_nil(t.block), num: count(u.id), sum: sum(u.satoshis)})
    |> group_by([u, t], not is_nil(t.block))
    |> Repo.all()
  end







  # TODO
  defp calc_tx_fee(funding_coins, coins) do
    size = Enum.sum([
      8,                                                        # version + locktime
      length(funding_coins) |> VarInt.encode() |> byte_size(),  # txin num
      Enum.reduce(funding_coins, 0, & &2 + txin_size(&1)),      # txins
      length(coins) |> VarInt.encode() |> byte_size(),          # txout num
      Enum.reduce(coins, 0, & &2 + txout_size(&1))              # txouts
    ])
    ceil(size * @sats_per_byte)
  end

  # TODO
  defp est_tx_fee(txins_num, txouts_num) do
    size = Enum.sum([
      8,                                                        # version + locktime
      VarInt.encode(txins_num) |> byte_size(),                  # txin num
      Enum.reduce(1..txins_num, 0, & &2 + txin_size(&1)),       # txins
      VarInt.encode(txouts_num) |> byte_size(),                 # txout num
      Enum.reduce(1..txouts_num, 0, & &2 + txout_size(&1))      # txouts
    ])
    ceil(size * @sats_per_byte)
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

  # TODO
  defp txin_size(_coin), do: @p2pkh_txin_size

  # TODO
  defp txout_size(_coin), do: @p2pkh_txout_size

end
