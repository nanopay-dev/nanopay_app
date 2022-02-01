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
  Funds a Pay Request using the given user's Fiat Wallet.

  Performs an Ecto.Multi routine as follows:

  1. debit fiat account
  2. spend to pay request
  3. sign utxo
  """
  @spec fund_pay_request_with_user_wallet(PayRequest.t(), User.t()) ::
    {:ok, %{
      fiat_txn: FiatWallet.Txn.t(),
      # todo,
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
    |> Multi.update(:pay_request, Ecto.Changeset.change(pay_request, %{status: :completed}))
    |> Repo.transaction()
  end

end
