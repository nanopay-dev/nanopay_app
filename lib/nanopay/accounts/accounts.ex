defmodule Nanopay.Accounts do
  @moduledoc """
  The Accounts context.
  """
  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Nanopay.Repo
  alias Nanopay.Accounts.{User, Profile}

  @doc """
  Gets a single user by it's user ID. Returns nil if no user with the id exists.
  """
  @spec get_user(binary()) :: User.t() | nil
  def get_user(user_id), do: Repo.get(User, user_id)

  @doc """
  Gets a single user by case-insensitive email address. Returns nil if no user
  with the email exists.
  """
  @spec get_user_by_email(binary()) :: User.t() | nil
  def get_user_by_email(email) do
    email = String.downcase(email)
    User
    |> where([u], fragment("lower(?)", u.email) == ^email)
    |> Repo.one()
  end

  @doc """
  Gets a single user by case-insensitive email and password. Returns nil if no
  user with the email and password exists.
  """
  @spec get_user_by_email_and_password(binary(), binary()) :: User.t() | nil
  def get_user_by_email_and_password(email, password) do
    case Argon2.check_pass(get_user_by_email(email), password) do
      {:ok, user} -> user
      {:error, _} -> nil
    end
  end

  @doc """
  Creates a new user and user profile with the given params.
  """
  @spec register_user(map(), map()) ::
    {:ok, %{user: User.t(), profile: Profile.t()}} |
    {:error, any()} |
    {:error, Ecto.Multi.name(), any(), %{required(Ecto.Multi.name()) => any()}}
  def register_user(user_params, profile_params) do
    Multi.new()
    |> Multi.insert(:user, User.auth_changeset(%User{}, user_params))
    |> Multi.insert(:profile, fn %{user: user} ->
      user
      |> Ecto.build_assoc(:profiles)
      |> Profile.changeset(profile_params)
    end)
    |> Repo.transaction()
  end
end
