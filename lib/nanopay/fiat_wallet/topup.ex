defmodule Nanopay.FiatWallet.Topup do
  use Ecto.Schema
  import Ecto.Changeset
  alias Nanopay.Accounts.User

  @template_params %{
    "usd_10" => %{amount: Money.new(:USD, 10), fee: Money.new(:USD, 2)},
    "usd_20" => %{amount: Money.new(:USD, 20), fee: Money.new(:USD, 3)},
    "usd_30" => %{amount: Money.new(:USD, 30), fee: Money.new(:USD, 4)}
  }
  @templates Map.keys(@template_params)

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "fiat_topups" do
    belongs_to :user, User

    field :type, :string
    field :status, Ecto.Enum, values: [pending: 0, paid: 1, cancelled: -1], default: :pending
    field :amount, Money.Ecto.Composite.Type
    field :fee, Money.Ecto.Composite.Type
    field :stripe_id, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(topup, attrs) do
    topup
    |> cast(attrs, [:type, :status, :stripe_id])
    |> apply_template()
    |> validate_required([:type, :status, :amount, :fee])
    |> validate_inclusion(:type, @templates)
  end

  @doc """
  Returns Stripe line item params (amount and fee) for the given topup.
  """
  @spec get_line_items(Ecto.Schema.t()) :: list(Stripe.Session.line_item())
  def get_line_items(%__MODULE__{type: type} = topup) do
    Enum.map [:amount, :fee], fn line ->
      money = Map.get(topup, line)
      {_, pennies, _, _} = Money.to_integer_exp(money)
      %{
        quantity: 1,
        price_data: %{
          currency: to_string(money.currency),
          product_data: get_product_data(line, type),
          unit_amount: pennies
        }
      }
    end
  end

  # Returns Stripe product for the topup type
  defp get_product_data(:amount, "usd_10") do
    %{name: "Ten buck topup", description: "We can add a lil description here..."}
  end

  defp get_product_data(:amount, "usd_20") do
    %{name: "Twenty buck topup"}
  end

  defp get_product_data(:amount, "usd_30") do
    %{name: "Thirty buck topup"}
  end

  defp get_product_data(:fee, _), do: %{name: "Topup fee"}

  # Applies defaults for the given topup type
  defp apply_template(%{changes: %{type: type}} = changes),
    do: change(changes, Map.get(@template_params, type, %{}))

  defp apply_template(changes), do: changes

end
