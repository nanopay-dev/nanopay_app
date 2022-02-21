defmodule NanopayWeb.App.RequireUserPlug do
  @moduledoc """
  Plug that requires a user to exist on the conn private data. Should be called
  after `NanopayWeb.App.UserTokenPlug` and will halt the connection if no user
  exists.
  """
  import Plug.Conn
  import Phoenix.Controller
  alias Nanopay.Accounts.User
  alias NanopayWeb.Router.Helpers, as: Routes

  @doc false
  def init(opts), do: opts

  @doc false
  def call(conn, _opts) do
    case conn.private[:current_user] do
      %User{} ->
        conn

      _ ->
        conn
        |> put_flash(:error, "Please log in")
        |> redirect(to: Routes.app_session_path(conn, :create))
        |> halt()
    end
  end

end
