defmodule Nanopay.Coinbox.Coin do
  @moduledoc """
  Channels:

  * 1: Inbox (topups and change)
  * 2: Pool (waiting for use in a funding tx)
  * 3: Used (given to a user for their tx)
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Nanopay.Coinbox.{Key, Txn}
  alias Nanopay.Payments.PayRequest
  alias BSV.{Script, Tx, UTXO}

  @typedoc "Key derviation path"
  @type derivation_path() :: String.t()

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "coins" do
    belongs_to :funding_tx, Txn, foreign_key: :funding_txid, references: :txid, type: :string, define_field: false
    belongs_to :spending_tx, Txn, foreign_key: :funding_txid, references: :txid, type: :string, define_field: false
    belongs_to :pay_request, PayRequest

    field :channel, Ecto.Enum, values: [inbox: 0, pool: 1, used: 2]
    field :path, :string
    field :satoshis, :integer
    field :script, :string
    field :funding_txid, :string
    field :funding_vout, :integer
    field :spending_txid, :string
    field :spending_vout, :integer
    field :locked_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(coin, attrs) do
    coin
    |> cast(attrs, [:channel, :path, :satoshis])
    |> validate_required([:channel, :path, :satoshis])
    |> validate_format(:path, Nanopay.regex(:keypath))
    |> put_script()
    |> validate_required([:script])
    |> validate_number(:satoshis, greater_than_or_equal_to: 150)
  end

  @doc false
  def funding_changeset(coin, attrs) do
    coin
    |> changeset(attrs)
    |> cast(attrs, [:funding_txid, :funding_vout])
    |> validate_required([:funding_txid, :funding_vout])
    |> validate_format(:funding_txid, Nanopay.regex(:sha256hex))
    |> validate_number(:funding_vout, greater_than_or_equal_to: 0)
  end

  @doc false
  def spending_changeset(coin, attrs) do
    coin
    |> changeset(attrs)
    |> cast(attrs, [:spending_txid, :spending_vout])
    |> validate_required([:spending_txid, :spending_vout])
    |> validate_format(:spending_txid, Nanopay.regex(:sha256hex))
    |> validate_number(:spending_vout, greater_than_or_equal_to: 0)
  end

  @doc """
  Returns a Coin built with the given parameters.
  """
  @spec init(non_neg_integer(), derivation_path(), non_neg_integer()) :: Schema.t()
  def init(channel, path, satoshis \\ 0) do
    %__MODULE__{}
    |> changeset(%{channel: channel, path: path, satoshis: satoshis})
    |> apply_changes()
  end

  @doc """
  Returns a Coin containing a funding script.
  """
  @spec init_funding(keyword()) :: Schema.t()
  def init_funding(opts \\ []) do
    inc = Keyword.get(opts, :inc, 0)
    %{year: year} = now = DateTime.utc_now()
    day = Date.day_of_year(now) + inc

    init(:inbox, "/inb/#{ year }/#{ day }")
  end

  @doc """
  Returns a Coin containing a change script.
  """
  @spec init_change(non_neg_integer(), keyword()) :: Schema.t()
  def init_change(satoshis, opts \\ []) do
    inc = Keyword.get(opts, :inc, 0)
    %{year: year, hour: hour, minute: minute} = now = DateTime.utc_now()
    day = Date.day_of_year(now)
    mins = (hour*60) + minute + inc

    init(:inbox, "/chg/#{ year }/#{ day }/#{ mins }", satoshis)
  end

  @doc """
  Returns a list of funding Coin structs, matched against the outputs of the
  given Tx.

  If no outputs are matched, an error is returned.
  """
  @spec from_funding_tx(Tx.t()) :: {:ok, list(Schema.t())} | {:error, term()}
  def from_funding_tx(%Tx{outputs: outputs} = tx) do
    coins = [0, -1, -2, 1]
    |> Enum.map(& init_funding(inc: &1))
    |> Enum.reduce([], fn %{script: script} = coin, results ->
      coins = outputs
      |> Enum.with_index()
      |> Enum.filter(fn {o, _i} ->
        Script.to_binary(o.script, encoding: :hex) == script
      end)
      |> Enum.map(fn {o, i} ->
        Map.merge(coin, %{
          satoshis: o.satoshis,
          funding_txid: Tx.get_txid(tx),
          funding_vout: i
        })
      end)

      results ++ coins
    end)

    if length(coins) > 0 do
      {:ok, coins}
    else
      {:error, :coins_not_found}
    end
  end

  @doc """
  Converts the given coin to a UTXO struct.
  """
  @spec to_bsv_utxo(Schema.t()) :: UTXO.t()
  def to_bsv_utxo(%__MODULE__{spending_txid: nil} = coin) do
    UTXO.from_params!(%{
      "txid" => coin.funding_txid,
      "vout" => coin.funding_vout,
      "satoshis" => coin.satoshis,
      "script" => coin.script
    })
  end

  def to_bsv_utxo(%__MODULE__{}),
    do: raise "cannot create utxo from spent coin"


  # Calculates a Script for the coin and puts it on the changeset
  defp put_script(%{valid?: true} = changes) do
    case get_field(changes, :script) do
      nil ->
        script = Key.derive_script(apply_changes(changes))
        put_change(changes, :script, Script.to_binary(script, encoding: :hex))
      _script ->
        changes
    end
  end

  defp put_script(changes), do: changes

end
