defmodule Nanopay.FiatWallet.Txn do
  use Ecto.Schema
  import Ecto.Changeset
  alias Nanopay.Accounts.User

  @supported_ccys ["USD"]

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "fiat_txns" do
    belongs_to :user, User

    field :description, :string
    field :base_amount, Money.Ecto.Composite.Type
    field :user_amount, Money.Ecto.Composite.Type
    field :balance, Money.Ecto.Composite.Type
    field :prev_balance, Money.Ecto.Composite.Type, virtual: true, default: Money.new(:USD, 0)
    field :user_ccy, :string, virtual: true, default: "USD"
    field :subject_type, :string
    field :subject_id, :binary_id
    field :subject, :any, virtual: true

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc false
  def changeset(fiat_tx, attrs) do
    fiat_tx
    |> cast(attrs, [:description, :base_amount, :prev_balance, :user_ccy, :subject])
    |> validate_required([:description, :base_amount, :user_ccy])
    |> validate_inclusion(:user_ccy, @supported_ccys)
    |> put_balance()
    |> put_user_amount()
    |> put_subject()
    |> normalize_money()
    |> validate_change(:balance, &validate_change/2)
  end

  # Calculates current balance and puts onto changeset
  defp put_balance(%{valid?: true, changes: %{base_amount: base_amount}} = changes) do
    prev_balance = Ecto.Changeset.get_field(changes, :prev_balance)
    put_change(changes, :balance, Money.add!(prev_balance, base_amount))
  end

  defp put_balance(changes), do: changes

  # Converts amount to user currency and puts onto changeset
  defp put_user_amount(%{valid?: true, changes: %{base_amount: base_amount}} = changes) do
    user_ccy = Ecto.Changeset.get_field(changes, :user_ccy)
    if user_ccy == Atom.to_string(base_amount.currency) do
      put_change(changes, :user_amount, base_amount)
    else
      put_change(changes, :user_amount, Money.to_currency!(base_amount, user_ccy))
    end
  end

  defp put_user_amount(changes), do: changes

  # Puts the subject struct name onto the changeset
  defp put_subject(%{valid?: true, changes: %{subject: subject}} = changes) do
    changes
    |> put_change(:subject_type, to_string(subject.__struct__))
    |> put_change(:subject_id, subject.id)
  end

  defp put_subject(changes), do: changes

  # Rounds fiat money amounts to 5 decimal places
  defp normalize_money(%{valid?: true} = changes) do
    Enum.reduce([:base_amount, :user_amount, :balance], changes, fn key, changes ->
      update_change(changes, key, & Money.round(&1, currency_digits: 5))
    end)
  end

  defp normalize_money(changes), do: changes

  # Ensures balance is not negative
  defp validate_change(:balance, balance) do
    case Money.cmp(balance, Money.new(:USD, 0)) do
      -1 ->
        [balance: "cannot be negative"]
      _ ->
        []
    end
  end
end
