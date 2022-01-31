defmodule Nanopay.Currency.RatesCache do
  @moduledoc """
  Simple implementation of `Money.ExchangeRates.Cache` behaviour. Delgates most
  methods to the `Money.ExchangeRates.Cache.Ets` cache, except `latest_rates/0`
  which merges crypto latest rates with the defaults.
  """
  @behaviour Money.ExchangeRates.Cache

  defdelegate init(), to: Money.ExchangeRates.Cache.Ets
  defdelegate historic_rates(date), to: Money.ExchangeRates.Cache.Ets
  defdelegate last_updated(), to: Money.ExchangeRates.Cache.Ets
  defdelegate store_historic_rates(rates, date), to: Money.ExchangeRates.Cache.Ets
  defdelegate store_latest_rates(rates, date), to: Money.ExchangeRates.Cache.Ets
  defdelegate terminate(), to: Money.ExchangeRates.Cache.Ets
  defdelegate get(key), to: Money.ExchangeRates.Cache.Ets
  defdelegate put(key, value), to: Money.ExchangeRates.Cache.Ets

  @doc false
  def latest_rates() do
    with {:ok, rates} <- Money.ExchangeRates.Cache.Ets.latest_rates() do
      {:ok, Map.merge(rates, get(:crypto_latest_rates))}
    end
  end

end
