defmodule NanopayWeb.App.AppLive do
  import Phoenix.LiveView
  alias NanopayWeb.Router.Helpers, as: Routes
  alias Nanopay.Accounts
  alias Nanopay.Accounts.User
  alias BSV.{PrivKey, PubKey}

  def on_mount(:default, _params, session, socket) do
    master_pubkey = Application.fetch_env!(:nanopay, :master_key)
    |> PrivKey.from_wif!()
    |> PubKey.from_privkey()
    |> PubKey.to_binary(encoding: :hex)

    profile = case Map.get(session, "current_user") do
      %User{} = user ->
        Accounts.get_user_profile(user)
      _ ->
        nil
    end

    socket = assign(socket, [
      master_pubkey: master_pubkey,
      current_user: Map.get(session, "current_user"),
      current_profile: profile,
      session_key: Map.get(session, "session_key")
    ])

    {:cont, socket}
  end

  def on_mount(:ensure_user, params, %{"current_user" => %User{} = user} = session, socket),
    do: on_mount(:default, params, session, assign(socket, :current_user, user))

  def on_mount(:ensure_user, _params, _session, socket),
    do: {:halt, push_redirect(socket, to: Routes.app_session_path(socket, :create))}

  def on_mount(:ensure_no_user, _params, %{"current_user" => %User{}} = _session, socket),
    do: {:halt, push_redirect(socket, to: Routes.app_dashboard_path(socket, :show))}

  def on_mount(:ensure_no_user, params, session, socket),
    do: on_mount(:default, params, session, socket)
end
