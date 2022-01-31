defmodule Nanopay.Payments.Fees do
  @moduledoc """
  Helper module for calculating fees for Pay requests (and other servcies later).
  """
  import Money.Sigil

  @pay_req_fees [
    t1: %{max: ~M[0.02]usd, rate: Decimal.new("0.5")},
    t2: %{max: ~M[0.20]usd, rate: Decimal.new("0.1")},
    t3: %{max: ~M[2.00]usd, rate: Decimal.new("0.05")},
    t4: %{max: ~M[20]usd, rate: Decimal.new("0.025")},
    t5: %{max: :infinity, rate: Decimal.new("0.01")}
  ]

  @pay_req_max ~M[10.00]usd

  @doc """
  Calculates the Pay request fee for the given amount.

  The amount can be given as a Money struct or integer (Satoshis).
  """
  @spec calc_pay_request(Money.t() | non_neg_integer()) :: Money.t()
  def calc_pay_request(money_or_sats) do
    with {:ok, rates} <- Money.ExchangeRates.latest_rates() do
      calc_pay_request(money_or_sats, rates)
    end
  end

  @spec calc_pay_request(Money.t() | non_neg_integer(), Money.ExchangeRates.t()) :: Money.t()
  def calc_pay_request(satoshis, rates) when is_integer(satoshis) do
    with {:ok, amount} <- Money.div(Money.new(:XSV, satoshis), 100_000_000),
         {:ok, amount_usd} <- Money.to_currency(amount, :USD, Map.take(rates, [:USD, :XSV]))
    do
      calc_pay_request(amount_usd, rates)
    end
  end

  def calc_pay_request(%{currency: :USD} = amount_usd, _rates) do
    fees = Enum.into(@pay_req_fees, %{})

    fee_usd = cond do
      Money.cmp!(amount_usd, fees.t4.max) == 1 ->
        amount_usd
        |> Money.sub!(fees.t4.max)
        |> Money.mult!(fees.t5.rate)
        |> Money.add!(max_fee_for(:t4))

      Money.cmp!(amount_usd, fees.t3.max) == 1 ->
        amount_usd
        |> Money.sub!(fees.t3.max)
        |> Money.mult!(fees.t4.rate)
        |> Money.add!(max_fee_for(:t3))

      Money.cmp!(amount_usd, fees.t2.max) == 1 ->
        amount_usd
        |> Money.sub!(fees.t2.max)
        |> Money.mult!(fees.t3.rate)
        |> Money.add!(max_fee_for(:t2))

      Money.cmp!(amount_usd, fees.t1.max) == 1 ->
        amount_usd
        |> Money.sub!(fees.t1.max)
        |> Money.mult!(fees.t2.rate)
        |> Money.add!(max_fee_for(:t1))

      true ->
        Money.mult!(amount_usd, fees.t1.rate)
    end

    case Money.cmp!(fee_usd, @pay_req_max) do
      1 -> @pay_req_max
      _ -> fee_usd
    end
  end

  # Calculates the maximum fee for the given level
  defp max_fee_for(t) do
    init = {Money.new(:USD, 0), Money.new(:USD, 0)}

    Enum.reduce_while @pay_req_fees, init, fn {key, tier}, {prev, fee} ->
      fee = tier.max
      |> Money.sub!(prev)
      |> Money.mult!(tier.rate)
      |> Money.add!(fee)

      case key do
        ^t -> {:halt, fee}
        _ -> {:cont, {tier.max, fee}}
      end
    end
  end

end
