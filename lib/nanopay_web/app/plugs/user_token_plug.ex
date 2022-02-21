defmodule NanopayWeb.App.UserTokenPlug do
  @moduledoc """
  Plug that verifies the token from the session and loads the user onto the
  connection private data.

  If there is no user token or the token isn't valid then the connection
  continues. `NanopayWeb.App.RequireUserPlug` should be used to enforce
  authentication.
  """
  import Plug.Conn
  alias Nanopay.Accounts
  alias Nanopay.Accounts.User
  alias NanopayWeb.App.Auth

  @doc false
  def init(opts), do: opts

  @doc false
  def call(conn, _opts) do
    with token when is_binary(token) <- get_session(conn, :user_token),
         {:ok, {user_id, session_key}} <- Auth.verify_token(token),
         %User{} = user <- Accounts.get_user(user_id)
    do
      conn
      |> put_private(:current_user_id, user_id)
      |> put_private(:current_user, user)
      |> put_private(:session_key, session_key)
    else
      _ -> conn
    end
  end

end
