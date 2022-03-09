defmodule Nanopay.Payments do
  @moduledoc """
  The Payments context.
  """
  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Nanopay.Repo
  alias Nanopay.Payments.{PayRequest, PayCtx}
  alias Nanopay.Accounts.User
  alias Nanopay.Coinbox
  alias Nanopay.Coinbox.{Coin, Unlocker}
  alias Nanopay.FiatWallet
  alias BSV.TxBuilder

  @doc """
  Gets a Pay request by it's ID. Returns nil if no Pay Request with the id exists.
  """
  @spec get_pay_request(binary()) :: PayRequest.t() | nil
  def get_pay_request(id), do: Repo.get(PayRequest, id)

  @doc """
  Gets a Pay request by it's ID and the given clauses.

  Useful for only returning Pay Requests of a given status.
  """
  @spec get_pay_request(binary(), Enum.t()) :: PayRequest.t()
  def get_pay_request(id, clauses) do
    Repo.get_by(PayRequest, Enum.into(clauses, %{id: id}))
  end

  @doc """
  Gets a Pay request by it's short ref. Returns nil if no Pay Request exists.
  """
  @spec get_pay_request_by_ref(String.t()) :: PayRequest.t() | nil
  def get_pay_request_by_ref(ref) do
    PayRequest
    |> where(fragment("encode(substring(sha256(id::text::bytea) FROM 1 FOR 4), 'hex') = ?", ^ref))
    |> order_by(desc: :inserted_at)
    |> Repo.one()
  end

  @doc """
  Gets a Pay request by it's short ref and the given clauses.

  Useful for only returning Pay Requests of a given status.
  """
  @spec get_pay_request_by_ref(String.t(), Enum.t()) :: PayRequest.t()
  def get_pay_request_by_ref(ref, clauses) do
    PayRequest
    |> where(fragment("encode(substring(sha256(id::text::bytea) FROM 1 FOR 4), 'hex') = ?", ^ref))
    |> order_by(desc: :inserted_at)
    |> Repo.get_by(Enum.into(clauses, %{}))
  end

  @doc """
  TODO
  """
  @spec get_pay_request_and_set_payee(binary(), User.t() | nil) :: PayRequest.t() | nil
  def get_pay_request_and_set_payee(id, %User{id: user_id}) do
    PayRequest
    |> select([p], p)
    |> where([p], p.id == ^id)
    |> update(set: [payee_id: ^user_id])
    |> Repo.one()
  end

  def get_pay_request_and_set_payee(id, nil), do: get_pay_request(id)

  @doc """
  Creates a Pay Requests with the given attributes.
  """
  @spec create_pay_request(map()) ::
    {:ok, PayRequest.t()} |
    {:error, Ecto.Changeset.t()}
  def create_pay_request(attrs \\ %{}) do
    %PayRequest{}
    |> PayRequest.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Sets the specified payee on the given Pay Request.
  """
  @spec set_pay_request_payee(PayRequest.t(), User.t()) ::
    {:ok, PayRequest.t()} |
    {:error, Ecto.Changeset.t()}
  def set_pay_request_payee(%PayRequest{} = pay_request, %User{id: user_id}) do
    pay_request
    |> Ecto.Changeset.change(%{payee_id: user_id})
    |> Repo.update()
  end

  @doc """
  Sets the specified status on the given Pay Request.
  """
  @spec set_pay_request_status(PayRequest.t(), atom()) ::
    {:ok, PayRequest.t()} |
    {:error, Ecto.Changeset.t()}
  def set_pay_request_status(%PayRequest{} = pay_request, status) do
    pay_request
    |> PayRequest.status_changeset(status)
    |> Repo.update()
  end

  @doc """
  Returns a list of the given users latest payments.
  """
  @spec latest_user_payments(User.t(), non_neg_integer()) :: list(PayRequest.t())
  def latest_user_payments(%User{id: user_id}, lmt \\ 5) do
    PayRequest
    |> where([p], p.payee_id == ^user_id and p.status == :completed)
    |> order_by(desc: :inserted_at)
    |> limit(^lmt)
    |> Repo.all()
  end

  @doc """
  Returns a paginated list of the given users payments.
  """
  @spec paginate_user_payments(User.t(), keyword()) :: Scrivener.Page.t()
  def paginate_user_payments(%User{id: user_id}, opts \\ []) do
    PayRequest
    |> where([p], p.payee_id == ^user_id and p.status == :completed)
    |> order_by(desc: :inserted_at)
    |> Repo.paginate(opts)
  end

  @doc """
  TODO
  """
  def user_payment_stats(%User{id: user_id}) do
    # Subquery fetch payments
    start = Date.add(Date.utc_today(), -30)
    data = from p in PayRequest,
      where: p.payee_id == ^user_id and p.status == :completed,
      where: type(p.completed_at, :date) >= ^start

    # Query joined to date series
    query = from p in subquery(data),
      right_join: d in fragment("SELECT generate_series(now() - '30 days'::interval, now(), '1 day'::interval)::date as day"),
      on: d.day == fragment("date(?)", p.completed_at),
      group_by: d.day,
      order_by: d.day,
      select: %{
        date: d.day,
        payments: count(p),
        amount: fragment("COALESCE(sum(amount(?) * amount(?)), 0)", p.amount, p.base_rate),
        fees: fragment("COALESCE(sum(amount(?) * amount(?)), 0)", p.fee, p.base_rate)
      }

    Repo.all(query)

  end

  @doc """
  Funds a Pay Request using the given user's Fiat Wallet.

  Performs an Ecto.Multi routine as follows:

  1. debit fiat account
  2. spend to pay request
  3. sign utxo
  """
  @spec fund_pay_request_with_user_wallet(PayRequest.t(), User.t()) ::
    {:ok, %{
      fiat_txn: FiatWallet.Txn.t(),
      coins: list(Coin.t()),
      txn: Coinbox.Txn.t(),
      signed_txin: BSV.TxIn.t()
    }} |
    {:error, any()} |
    {:error, Ecto.Multi.name(), any(), %{required(Ecto.Multi.name()) => any()}}
  def fund_pay_request_with_user_wallet(%PayRequest{} = pay_request, %User{} = user) do
    fiat_txn = user
    |> Ecto.build_assoc(:fiat_txns)
    |> FiatWallet.Txn.changeset(%{
      description: pay_request.description,
      base_amount: Money.mult!(PayRequest.get_total(pay_request, :USD), -1),
      prev_balance: FiatWallet.get_user_balance(user),
      subject: pay_request
    })

    Multi.new()
    # 1. debit fiat account
    |> Multi.insert(:fiat_txn, fiat_txn)
    # 2. spend to pay request
    |> Coinbox.spend_to(pay_request, broadcast: false)
    # 3. sign utxo
    |> Multi.run(:signed_txin, fn _repo, %{{:output, 0} => coin} ->
      input = coin
      |> Coin.to_bsv_utxo()
      |> Unlocker.unlock(%{coin: coin}, PayCtx.to_opts(pay_request.ctx))
      tx = TxBuilder.to_tx(%TxBuilder{inputs: [input]})
      {:ok, hd(tx.inputs)}
    end)
    |> Repo.transaction()
  end

  @doc """
  TODO

  1. build coins and validate they exist in txn
  2. insert txn
  3. insert coins
  4. set pay request to funded
  5. broadcast txn
  6. sign utxo
  """
  def fund_pay_request_with_tx(%PayRequest{id: id} = pay_request, %BSV.Tx{} = tx) do
    Multi.new()
    # 1. build coins and validate they exist in txn
    |> Multi.run(:coins, fn _repo, _changes ->
      coins = PayRequest.build_coins(pay_request)
      case Enum.all?(coins, & is_number(find_tx_vout(tx, &1))) do
        true -> {:ok, coins}
        false -> {:error, "Tx does not satisfy PayRequest"}
      end
    end)
    # 2. insert txn
    |> Multi.insert(:txn, fn _changes ->
      tx
      |> Coinbox.Txn.from_bsv_tx(status: :pushed)
      |> Ecto.Changeset.change()
    end)
    # 3. insert coins
    |> Multi.merge(fn %{txn: txn, coins: coins} ->
      coins
      |> Enum.map(& {Map.put(&1, :pay_request_id, id), find_tx_vout(tx, &1)})
      |> Enum.reduce(Multi.new(), fn {coin, i}, multi ->
        changeset = Coin.funding_changeset(coin, %{funding_txid: txn.txid, funding_vout: i})
        Multi.insert(multi, {:output, i}, changeset)
      end)
    end)
    # 4. set pay request to funded
    |> Multi.update(:pay_request, PayRequest.status_changeset(pay_request, :funded))
    # 5. broadcast txn
    # TODO
    # 6. sign utxo
    |> Multi.run(:signed_txin, fn _repo, changes ->
      {_key, coin} = Enum.find(changes, fn {k, v} -> match?({:output, _}, k) and v.channel == :used end)
      input = coin
      |> Coin.to_bsv_utxo()
      |> Unlocker.unlock(%{coin: coin}, PayCtx.to_opts(pay_request.ctx))
      tx = TxBuilder.to_tx(%TxBuilder{inputs: [input]})
      {:ok, hd(tx.inputs)}
    end)
    |> Repo.transaction()
  end

  defp find_tx_vout(tx, coin) do
    Enum.find_index(tx.outputs, fn txout ->
      BSV.Script.to_binary(txout.script, encoding: :hex) == coin.script and txout.satoshis >= coin.satoshis
    end)
  end

  @doc """
  Updates a Pay Request as completed and updates the funding and spending coins.

  Performs an Ecto.Multi routine as follows:

  1. insert target txn
  2. update funding utxo with spending txid
  3. set funding txn as pushed
  4. update pay request as completed
  """
  @spec complete_pay_request(PayRequest.t(), map()) ::
    {:ok, %{
      txn: Coinbox.Txn.t(),
      coins: list(Coinbox.Coin.t()),
      spending_txns: list(Coinbox.Txn.t()),
      pay_request: PayRequest.t()
    }} |
    {:error, any()} |
    {:error, Ecto.Multi.name(), any(), %{required(Ecto.Multi.name()) => any()}}
  def complete_pay_request(%PayRequest{id: id} = pay_request, params) do
    Multi.new()
    # 1. insert target txn
    |> Multi.insert(:txn, Coinbox.Txn.changeset(%Coinbox.Txn{status: :pushed}, params))
    # 2. update funding utxo with spending txid
    |> Multi.update_all(:coins, fn %{txn: %{txid: txid}} ->
      from c in Coinbox.Coin,
        select: c,
        where: c.channel == :used and c.pay_request_id == ^id and is_nil(c.spending_txid),
        update: [set: [spending_txid: ^txid, spending_vout: 0]]
    end, [])
    # 3. set funding txn as pushed
    |> Multi.update_all(:spending_txns, fn %{coins: {_, coins}} ->
      txids = Enum.map(coins, & &1.funding_txid)
      from t in Coinbox.Txn, where: t.txid in ^txids
    end, set: [status: :pushed])
    # 4. update pay request as completed
    |> Multi.update(:pay_request, PayRequest.status_changeset(pay_request, :completed))
    |> Repo.transaction()
  end

end
