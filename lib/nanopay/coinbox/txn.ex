defmodule Nanopay.Coinbox.Txn do
  use Ecto.Schema
  import Ecto.Changeset
  alias BSV.{Tx, TxBuilder}

  @primary_key {:txid, :string, autogenerate: false}
  @foreign_key_type :string
  schema "txns" do
    field :rawtx, :binary
    field :status, Ecto.Enum, values: [pending: 0, queued: 1, pushed: 2, failed: -1], default: :pending
    field :block, :integer
    field :mapi_status, :map
    field :mapi_count, :integer, default: 0
    field :prev_mapi_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(txn, attrs) do
    txn
    |> cast(attrs, [:txid, :status, :rawtx])
    |> validate_required([:txid, :status])
    |> validate_format(:txid, Nanopay.regex(:sha256hex))
  end

  @doc false
  def mapi_changeset(txn, attrs) do
    txn
    |> cast(attrs, [:mapi_status])
    |> validate_required([:mapi_status])
    |> put_block_height()
    |> put_status()
    |> inc_mapi_count()
    |> put_change(:prev_mapi_at, DateTime.truncate(DateTime.utc_now(), :second))
  end

  @doc """
  Creates a Txn from the BSV.Tx struct.
  """
  @spec from_bsv_tx(Tx.t()) :: Schema.t()
  def from_bsv_tx(%Tx{} = tx, opts \\ []) do
    status = Keyword.get(opts, :status, :pending)
    struct(__MODULE__, [
      txid: Tx.get_txid(tx),
      rawtx: Tx.to_binary(tx),
      status: status
    ])
  end

  @doc """
  Creates a Txn from the BSV.TxBuilder struct.
  """
  @spec from_bsv_tx_builder(TxBuilder.t()) :: Schema.t()
  def from_bsv_tx_builder(%TxBuilder{} = builder, opts \\ []) do
    builder
    |> TxBuilder.to_tx()
    |> from_bsv_tx(opts)
  end

  # Resets or increments the mapi status count
  defp inc_mapi_count(%{changes: %{status: :pushed}} = changeset) do
    put_change(changeset, :mapi_count, 0)
  end

  defp inc_mapi_count(changeset) do
    count = fetch_field!(changeset, :mapi_count)
    put_change(changeset, :mapi_count, count + 1)
  end

  # Puts block height into changeset from mapi status
  defp put_block_height(%{valid?: true} = changeset) do
    case get_change(changeset, :mapi_status) do
      %{"block_height" => block} when is_integer(block) and block > 0 ->
        put_change(changeset, :block, block)
      _ ->
        changeset
    end
  end

  defp put_block_height(changeset), do: changeset

  # Sets the ststaus to pushed if the mapi payload contains a txid
  defp put_status(%{valid?: true} = changeset) do
    case get_change(changeset, :mapi_status) do
      %{"txid" => _txid} ->
        put_change(changeset, :status, :pushed)
      _ ->
        changeset
    end
  end

  defp put_status(changeset), do: changeset

end
