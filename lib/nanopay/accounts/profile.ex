defmodule Nanopay.Accounts.Profile do
  @moduledoc """
  User Profile schema. A user may have many profiles.

  Profiles are associated with a private key and are used to authenticate with
  3rd party apps. All subsequence transactions can be linked back to the
  profile.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Nanopay.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "profiles" do
    belongs_to :user, User

    field :handle, :string
    field :pubkey, :string
    field :enc_privkey, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:handle, :pubkey, :enc_privkey])
    |> validate_required([:handle, :pubkey, :enc_privkey])
    |> validate_length(:handle, max: 15)
    |> validate_format(:handle, Nanopay.regex(:handle))
    |> validate_format(:pubkey, Nanopay.regex(:pubkey))
    |> unique_constraint(:handle)
    |> unique_constraint(:pubkey)
  end
end
