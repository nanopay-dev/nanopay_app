defmodule Nanopay.Accounts.KeyData do
  @moduledoc """
  User KeyData embedded schema. Used to store encrypted key data.

  Always contains the encrypted secret key (encrypted with the user recovery key).
  If the status is `:custodial` then also contains the encrytped recovery key
  which the app can decrypt by deriving a key using the recovery path.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :status, Ecto.Enum, values: [noncustodial: 0, custodial: 1], default: :custodial
    field :rec_path, :string
    field :enc_secret, :string
    field :enc_recovery, :string
  end

  @doc false
  def changeset(key_data, attrs) do
    key_data
    |> cast(attrs, [:status, :rec_path, :enc_secret, :enc_recovery])
    |> validate_required([:status, :enc_secret])
    |> maybe_require_enc_revovery()
  end

  # Require encrypted recovery key if status is custodial
  defp maybe_require_enc_revovery(changes) do
    case Ecto.Changeset.get_field(changes, :status) do
      :custodial ->
        validate_required(changes, [:rec_path, :enc_recovery])
      _ -> changes
    end
  end
end
