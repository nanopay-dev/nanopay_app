defmodule Nanopay.Currency.CryptoRates do
  @moduledoc """
  GenServer process that periodically fetches and stores crypto rates in the
  configured `Money.ExchangeRates.Cache`.
  """
  use GenServer

  @default_interval 300_000

  defstruct api_host: :coingecko,
            retrieve_every: @default_interval

  @doc """
  Starts the server linked to the current process.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []),
    do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc """
  Returns the latest Crypto rates.
  """
  @spec latest_rates() :: Money.ExchangeRates.t()
  def latest_rates(), do: GenServer.call(__MODULE__, :latest_rates)

  @impl true
  def init(opts) do
    config = struct(__MODULE__, opts)

    schedule_work(0)
    schedule_work(config.retrieve_every)
    {:ok, config}
  end

  @impl true
  def handle_call(:latest_rates, _from, config) do
    {:reply, get_latest_rates(config), config}
  end

  @impl true
  def handle_info(:latest_rates, config) do
    get_latest_rates(config)
    schedule_work(config.retrieve_every)
    {:noreply, config}
  end

  # Returns the HTTP client for the configured host
  defp client(%{api_host: :coingecko}) do
    middleware = [
      {Tesla.Middleware.BaseUrl, "https://api.coingecko.com/api/v3"},
      Tesla.Middleware.JSON,
    ]

    Tesla.client(middleware)
  end

  # Gets the latest rates from the configured host, stores the rates in the
  # cache and returns the rates
  defp get_latest_rates(%{api_host: :coingecko} = config) do
    query = [ids: "bitcoin-cash-sv", vs_currencies: "USD", include_last_updated_at: true]
    case Tesla.get(client(config), "/simple/price", query: query) do
      {:ok, env} ->
        usd_rate = case get_in(env.body, ["bitcoin-cash-sv", "usd"]) do
          rate when is_float(rate) -> Decimal.from_float(rate)
          rate when is_integer(rate) -> Decimal.new(rate)
        end

        rates = %{
          XSV: Decimal.div(Decimal.new(1), usd_rate)
        }

        time = env.body
        |> get_in(["bitcoin-cash-sv", "last_updated_at"])
        |> DateTime.from_unix()

        Money.ExchangeRates.Cache.cache.put(:crypto_latest_rates, rates)
        Money.ExchangeRates.Cache.cache.put(:crypto_last_updated, time)

        {:ok, rates}

      {:error, error} ->
        {:error, error}
    end
  end

  # Schedules the process to fetch latest rates after the given interval
  defp schedule_work(interval) when is_integer(interval),
    do: Process.send_after(self(), :latest_rates, interval)

end
