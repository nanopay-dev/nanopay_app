defmodule Nanopay.Accounts.User do
  @moduledoc """
  User schema. A user can authenticate with the app, create many profiles from
  which they can connect to 3rd party apps and enjoy the Bitcoin world.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Nanopay.Accounts.{Profile, KeyData}
  #alias Nanopay.FiatWallet
  #alias Nanopay.FiatWallet.Topup

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    has_many :profiles, Profile
    embeds_one :key_data, KeyData
    #has_many :fiat_txns, FiatWallet.Txn
    #has_many :topups, Topup

    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :verified_at, :utc_datetime
    field :stripe_id, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:stripe_id])
  end

  @doc """
  Returns an auth changeset. Registration and changes of email or password
  by definition require resupplying encrypted keydata as the email and password
  combo are used client side to derive the recovery key.
  """
  def auth_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> cast_embed(:key_data, with: &KeyData.changeset/2)
    |> put_password_hash()
    |> validate_required([:email, :password_hash])
    |> validate_format(:email, Nanopay.regex(:email))
    |> unique_constraint(:email)
  end

  # Hashes the given password
  defp put_password_hash(%{valid?: true, changes: %{password: password}} = changes) do
    change(changes, password_hash: Argon2.hash_pwd_salt(password))
  end

  defp put_password_hash(changes), do: changes
end
