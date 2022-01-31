# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :nanopay,
  ecto_repos: [Nanopay.Repo],
  generators: [binary_id: true]

# Configures the endpoint
config :nanopay, NanopayWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: NanopayWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Nanopay.PubSub,
  live_view: [signing_salt: "aks66R6V"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :nanopay, Nanopay.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.0",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Money config
config :ex_money,
  default_cldr_backend: Nanopay.Cldr,
  exchange_rates_cache_module: Nanopay.Currency.RatesCache,
  exchange_rates_retrieve_every: 3600_000,
  open_exchange_rates_app_id: "xXxXxXxXxXx"

# Tesla config
config :tesla, :adapter, Tesla.Adapter.Mint

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
