defmodule NanopayWeb.Router do
  use NanopayWeb, :router

  pipeline :browser do
    plug :accepts, ["html", "json"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {NanopayWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :app do
    plug NanopayWeb.App.UserTokenPlug
  end

  pipeline :app_auth do
    plug NanopayWeb.App.RequireUserPlug
  end

  pipeline :p2p do
    plug :accepts, ["bsv", "json"]
  end

  pipeline :widget do
    plug NanopayWeb.App.UserTokenPlug
    plug :delete_resp_header, "x-frame-options"
  end

  pipeline :openapi do
    plug OpenApiSpex.Plug.PutApiSpec, module: NanopayWeb.API.Spec
  end

  # Base API refers to internal private APIs
  # TODO - authenticate
  scope "/api/base", NanopayWeb.API.Base, as: :base_api do
    pipe_through :api

    resources "/fund", FundingController, singleton: true, only: [:show, :create]
    resources "/stats", StatsController, only: [:index]
  end

  # Versioned API - public APIs
  scope "/api/v1", NanopayWeb.API.V1, as: :v1_api do
    pipe_through :openapi

    resources "/pay_requests", PayRequestController, only: [:show, :create]
    post "/pay_requests/:id/complete", PayRequestController, :complete
  end

  # Generic one-off API routes
  scope "/" do
    pipe_through :api

    get "/.well-known/bsvalias", NanopayWeb.P2P.PaymailController, :capabilities
    get "/api/openapi", OpenApiSpex.Plug.RenderSpec, []
  end

  # P2P endpoints
  scope "/p2p", NanopayWeb.P2P, as: :p2p do
    pipe_through :p2p

    get "/bip270/payment/:id", Bip270Controller, :show
    post "/bip270/payment/:id", Bip270Controller, :pay

    post "/paymail/:paymail/dest", PaymailController, :payment_destination
    post "/paymail/:paymail/tx", PaymailController, :transactions
  end

  # App routes - authenticated
  scope "/app", NanopayWeb.App, as: :app do
    pipe_through [:browser, :app, :app_auth]

    delete "/auth", AuthController, :delete

    live_session :authenticated,
      session: {NanopayWeb.App.Auth, :get_auth_session, []},
      on_mount: {NanopayWeb.App.AppLive, :ensure_user},
      root_layout: {NanopayWeb.App.LayoutView, :root}
    do
      live "/", DashboardLive, :show
      live "/wallet", WalletLive, :index
      live "/wallet/txn/:id", WalletLive, :show
      live "/payments", PaymentsLive, :index
      live "/payments/:id", PaymentsLive, :show
    end
  end

  # App routes - non authenticated
  scope "/app", NanopayWeb.App, as: :app do
    pipe_through [:browser, :app]

    post "/auth", AuthController, :create
    get "/topup/:id/paid", TopupController, :paid
    get "/topup/:id/cancelled", TopupController, :cancelled

    live_session :unauthenticated,
      session: {NanopayWeb.App.Auth, :get_auth_session, []},
      on_mount: {NanopayWeb.App.AppLive, :ensure_no_user},
      root_layout: {NanopayWeb.App.LayoutView, :root}
    do
      live "/register", RegistrationLive, :create
      live "/login", SessionLive, :create
    end
  end

  scope "/widget/v1", NanopayWeb.Widget.V1, as: :widget do
    pipe_through [:browser, :widget]

    live_session :default,
      session: {NanopayWeb.App.Auth, :get_auth_session, []},
      on_mount: NanopayWeb.App.AppLive,
      root_layout: {NanopayWeb.Widget.LayoutView, :root}
    do
      live "/pay_requests/:id", PayRequestLive, :show
    end
  end

  scope "/", NanopayWeb do
    pipe_through :browser

    #get "/", PageController, :index
  end

  scope "/" do
    pipe_through :browser
    get "/swaggerui", OpenApiSpex.Plug.SwaggerUI, path: "/api/openapi"
  end


  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: NanopayWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
