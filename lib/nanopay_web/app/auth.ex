defmodule NanopayWeb.App.Auth do
  @moduledoc """
  Auth module containing helper functions related to user authentication.
  """
  alias Nanopay.Accounts.User

  @max_age 86400
  @salt "user.auth"

  @doc """
  Returns a map containing the current user and session key if it exists.
  Used for passing prvate connection data to a liveview session.
  """
  @spec get_auth_session(Plug.Conn.t()) :: map()
  def get_auth_session(conn) do
    conn.private
    |> Map.take([:current_user_id, :current_user, :session_key])
    |> Enum.map(fn {key, value} -> {Atom.to_string(key), value} end)
    |> Enum.into(%{})
  end

  @doc """
  Generates a random 128bit session key, base64 encoded.
  """
  @spec generate_session_key() :: String.t()
  def generate_session_key(),
    do: :crypto.strong_rand_bytes(16) |> Base.encode64()

  @doc """
  Generates a token for the given user and session key.
  """
  @spec generate_token(User.t(), String.t()) :: String.t()
  def generate_token(%User{} = user, session_key),
    do: Phoenix.Token.sign(NanopayWeb.Endpoint, @salt, {user.id, session_key})

  @doc """
  Verifies the given user and returns the user id and session key.
  """
  @spec verify_token(String.t()) :: {:ok, {String.t(), String.t()}} | {:error, term()}
  def verify_token(token),
    do: Phoenix.Token.verify(NanopayWeb.Endpoint, @salt, token, max_age: @max_age)

end
