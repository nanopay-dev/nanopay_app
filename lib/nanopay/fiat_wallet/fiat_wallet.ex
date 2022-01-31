defmodule Nanopay.FiatWallet do
  @moduledoc """
  The Accounts context.
  """
  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Nanopay.Repo
  alias Nanopay.Accounts.User
  alias Nanopay.FiatWallet.{Topup, Txn}

  @doc """
  Gets a Topup by it's ID. Returns nil if no topud with the id exists.
  """
  @spec get_topup(binary()) :: Topud.t() | nil
  def get_topup(id), do: Repo.get(Topup, id)

  @doc """
  Gets a pending Topup by it's ID. Returns nil if no topud with the id exists.
  """
  @spec get_pending_topup(binary()) :: Topud.t() | nil
  def get_pending_topup(id) do
    Topup
    |> where([t], t.status == :pending)
    |> Repo.get(id)
  end

  @doc """
  Create's a topup for the user with the given params.
  """
  @spec create_user_topup(User.t(), map()) ::
    {:ok, Topup.t()} |
    {:error, Ecto.Changeset.t()}
  def create_user_topup(%User{} = user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:topups)
    |> Topup.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Sets the Topup as paid and tagging with the Stripe session ID.
  Creates a Fiat Txn for the topup user.
  """
  @spec topup_paid(Topup.t(), Stripe.Session.t()) ::
    {:ok, %{topup: Topup.t(), txn: Txn.t(), user: User.t()}} |
    {:error, any()} |
    {:error, Ecto.Multi.name(), any(), %{required(Ecto.Multi.name()) => any()}}
  def topup_paid(%Topup{} = topup, session) do
    topup = Repo.preload(topup, :user)
    balance = get_user_balance(topup.user)
    txn = Ecto.build_assoc(topup.user, :fiat_txns, %{prev_balance: balance})

    Multi.new()
    |> Multi.update(:topup, Topup.changeset(topup, %{status: :paid, stripe_id: session.id}))
    |> Multi.insert(:txn, Txn.changeset(txn, %{description: "Wallet topup", base_amount: topup.amount, subject: topup}))
    |> Multi.update(:user, User.changeset(topup.user, %{stripe_id: session.customer}))
    |> Repo.transaction()
  end

  @doc """
  Sets the Topup as cancelled.
  """
  @spec topup_cancelled(Topup.t()) :: {:ok, Topup.t()}
  def topup_cancelled(%Topup{} = topup) do
    topup
    |> Topup.changeset(%{status: :cancelled})
    |> Repo.update()
  end

  @doc """
  Returns the Fiat Wallet balance of the given user.
  """
  @spec get_user_balance(User.t()) :: Money.t()
  def get_user_balance(%User{id: user_id}) do
    txn = Txn
    |> where([t], user_id: ^user_id)
    |> order_by([t], desc: t.id)
    |> limit(1)
    |> Repo.one()

    # Extract the balance or return zero
    case txn do
      %Txn{balance: balance} ->
        balance
      nil ->
        Map.get(%Txn{}, :prev_balance)
    end
  end

end
