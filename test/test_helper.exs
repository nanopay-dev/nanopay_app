ExUnit.start(exclude: [:pending])
Ecto.Adapters.SQL.Sandbox.mode(Nanopay.Repo, :manual)

# Setup rates for tests
Money.ExchangeRates.Cache.cache.put(:latest_rates, %{USD: Decimal.new("1")})
Money.ExchangeRates.Cache.cache.put(:crypto_latest_rates, %{XSV: Decimal.new("100.00")})
