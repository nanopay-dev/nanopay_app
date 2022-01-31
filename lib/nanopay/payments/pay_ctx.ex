defmodule Nanopay.Payments.PayCtx do
  @moduledoc """
  Payment context embedded schema.

  Provides a way to specifiy attributes used when signing an input.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :version, :integer, default: 1
    field :outhash, :string
    field :locktime, :integer, default: 0
    field :sighash_type, :integer, default: 0x41
  end

  @doc false
  def changeset(key_data, attrs) do
    key_data
    |> cast(attrs, [:version, :outhash, :locktime, :sighash_type])
    |> validate_required([:version, :outhash, :locktime, :sighash_type])
    |> validate_number(:version, greater_than_or_equal_to: 1)
    |> validate_format(:outhash, Nanopay.regex(:sha256hex))
    |> validate_number(:locktime, greater_than_or_equal_to: 0)
  end

  @doc """
  TODO
  """
  @spec to_opts(Ecto.Schema.t()) :: keyword()
  def to_opts(%__MODULE__{} = ctx) do
    opts = Map.take(ctx, [:version, :locktime, :sighash_type])

    case Base.decode16(ctx.outhash, case: :mixed) do
      {:ok, outhash} ->
        opts
        |> Map.put(:outhash, outhash)
        |> Enum.map(& &1)
      :error ->
        Enum.map(opts, & &1)
    end
  end

end
