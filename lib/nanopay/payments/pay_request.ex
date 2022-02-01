defmodule Nanopay.Payments.PayRequest do
  use Ecto.Schema
  import Ecto.Changeset
  alias Nanopay.Payments.{Fees, PayCtx}

  # TODO - explain these
  @minimum_sats 140
  @minimum_fee Money.new(:XSV, "0.00000150")
  @overhead_sats 150

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "pay_requests" do
    embeds_one :ctx, PayCtx

    field :status, Ecto.Enum, values: [pending: 0, funded: 1, completed: 2], default: :pending
    field :keypath, :string
    field :description, :string
    field :satoshis, :integer, virtual: true
    field :amount, Money.Ecto.Composite.Type
    field :fee, Money.Ecto.Composite.Type
    field :base_rate, Money.Ecto.Composite.Type

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(pay_request, attrs) do
    pay_request
    |> cast(attrs, [:status, :keypath, :description, :satoshis])
    |> gen_keypath()
    |> validate_format(:keypath, Nanopay.regex(:keypath))
    |> cast_embed(:ctx, required: true, with: &PayCtx.changeset/2)
    |> validate_required([:status, :description, :satoshis])
    |> validate_length(:description, max: 140)
    |> validate_number(:satoshis, greater_than_or_equal_to: 0)
    |> put_money_fields()
  end

  @doc """
  Returns the Pay Request total required (amount + fee).

  Optionally a currency code can be given as the second argument.
  """
  @spec get_total(Schema.t(), Money.currency_code() | nil) :: Money.t()
  def get_total(pay_request, ccy \\ :XSV)

  def get_total(%__MODULE__{amount: amount, fee: fee}, :XSV),
    do: Money.add!(amount, fee)

  def get_total(%__MODULE__{amount: amount, fee: fee}, ccy),
    do: Money.add!(amount, fee) |> Money.to_currency!(ccy)

  @doc """
  Returns a hex encoded 4 byte reference of the Pay Request.

  This is taken from the UUID and is considered "unique enough" within a
  reasonably short time frame.
  """
  @spec get_ref(Schema.t()) :: String.t()
  def get_ref(%__MODULE__{id: id}) do
    <<ref::binary-size(4), _::binary>> = BSV.Hash.sha256(id)
    Base.encode16(ref, case: :lower)
  end

  @doc """
  Returns a Paymail address for the Pay Request.
  """
  @spec get_paymail(Schema.t()) :: String.t()
  def get_paymail(%__MODULE__{} = pay_request) do
    ref = get_ref(pay_request)
    host = Application.fetch_env!(:nanopay, :paymail_host)
    "pr-#{ ref }@#{ host }"
  end

  # Generates a random keypath if it is blank
  defp gen_keypath(%{valid?: true} = changes) do
    # TODO this should be more sophisticated
    # only if it is associated to a user should it not be auto-generated
    case get_field(changes, :keypath) do
      nil ->
        chunks = Enum.map(1..3, fn _ ->
          :crypto.strong_rand_bytes(5)
          |> Base.encode16(case: :lower)
        end)

        put_change(changes, :keypath, "/" <> Enum.join(chunks, "/"))
      _script ->
        changes
    end
  end

  # Calculates the fee, puts onto changeset and normalises all money fields
  defp put_money_fields(%{valid?: true} = changes) do
    satoshis = get_field(changes, :satoshis, 0)

    with {:ok, rates} <- Money.ExchangeRates.latest_rates(),
         {:ok, amount} <- Money.div(Money.new(:XSV, max(@minimum_sats, satoshis)), 100_000_000),
         %Money{} = fee_usd <- Fees.calc_pay_request(satoshis + @overhead_sats, rates),
         {:ok, fee} <- Money.to_currency(fee_usd, :XSV, Map.take(rates, [:USD, :XSV])),
         {:ok, base_rate} <- Money.div(Money.new(:USD, 1), rates[:XSV])
    do
      fee = if Money.cmp(@minimum_fee, fee) == 1, do: @minimum_fee, else: fee
      change(changes, %{
        amount:     Money.round(amount, currency_digits: 8),
        fee:        Money.round(fee, currency_digits: 8),
        base_rate:  Money.round(base_rate, currency_digits: 2)
      })
    end
  end

  defp put_money_fields(changes), do: changes

end
