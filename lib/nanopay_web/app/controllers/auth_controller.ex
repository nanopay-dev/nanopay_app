defmodule NanopayWeb.App.AuthController do
  @moduledoc """
  AuthController for authenticating users.
  """
  use NanopayWeb, :controller
  alias Nanopay.Accounts
  alias Nanopay.Accounts.User
  alias NanopayWeb.App.Auth

  action_fallback :handle_error

  @doc """
  POST /auth

  Authenticates with the given email and password params. If successful creates
  a new session key and user token.
  """
  def create(conn, %{"email" => email, "password" => password}) do
    with %User{} = user <- Accounts.get_user_by_email_and_password(email, password) do
      session_key = Auth.generate_session_key()
      token = Auth.generate_token(user, session_key)

      conn
      |> renew_session()
      |> put_session(:user_token, token)
      |> put_session(:live_token_id, "user_session:#{session_key}")
      |> put_status(:created)
      |> render("session.json", session_key: session_key, user: user)
    else
      _ ->
        {:error, :unauthenticated}
    end
  end

  @doc """
  DELETE /auth

  Deletes the current session.
  """
  def delete(conn, _params) do
    conn
    |> renew_session()
    |> put_flash(:info, "Successfully signed out")
    |> redirect(to: Routes.app_session_path(conn, :create))
  end

  # Securely renews the session
  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  # Handles authentication errors
  defp handle_error(conn, {:error, :unauthenticated}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(NanopayWeb.API.ErrorView)
    |> render("error.json", error: "Invalid email or password")
  end
end
