defmodule Nanopay.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @mix_env Mix.env()

  @doc """
  Returns the application environment set as the PHX_ENV runtime environment
  variable, falling back to the result of `Mix.env()` at compile time.
  """
  @spec env() :: String.t()
  def env(), do: System.get_env("PHX_ENV", Atom.to_string(@mix_env))

  @doc """
  Returns a boolean if the given value matches the current application environment.
  """
  @spec env?(String.t() | atom()) :: boolean()
  def env?(e) when is_atom(e), do: env?(Atom.to_string(e))
  def env?(e) when is_binary(e), do: env() == e

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Nanopay.Repo,
      # Start the Telemetry supervisor
      NanopayWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Nanopay.PubSub},
      # Start the Endpoint (http/https)
      NanopayWeb.Endpoint,
      # Start private currency store and define BSV currency
      Cldr.Currency,
      {Task, fn ->
        Cldr.Currency.new(:XSV, alt_code: :BSV, name: "Bitcoin SV", digits: 8, symbol: "₿")
      end},
      # Crontab
      Nanopay.Scheduler
    ]

    # Append exchange rate and MAPI processes unless in TEST
    children = unless env?(:test) do
      mapi_opts = Application.fetch_env!(:nanopay, :mapi)
      children ++ [
        Nanopay.Currency.CryptoRates,
        {Nanopay.MAPI.Queue, mapi_opts},
        {Nanopay.MAPI.Processor, mapi_opts}
      ]
    else
      children
    end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Nanopay.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    NanopayWeb.Endpoint.config_change(changed, removed)
    :ok
  end


end
