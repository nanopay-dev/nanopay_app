defmodule Nanopay.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

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
      NanopayWeb.Endpoint
      # Start a worker by calling: Nanopay.Worker.start_link(arg)
      # {Nanopay.Worker, arg}
    ]

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
