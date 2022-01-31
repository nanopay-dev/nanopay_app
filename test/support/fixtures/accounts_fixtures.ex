defmodule Nanopay.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating entities via the
  `Nanopay.Accounts` context.
  """
  alias Nanopay.Accounts

  @user_params %{
    email: "john@example.com",
    password: "a362fb1354c0a69cfd9802fc2738aeac79950b585189a4809221a31a28128bd0",
    key_data: %{
      rec_path: "e/123",
      enc_secret: "FSO4k+jC",
      enc_recovery: "O1jEamz/DxMe"
    }
  }

  @profile_params %{
    handle: "johndoe",
    pubkey: "03009910c3390271cd7500c4cb5571230228c1ccbb1ebced3e5f53b063172981cb",
    enc_privkey: "secretkey"
  }

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    user_params = Enum.into(attrs, @user_params)
    with {:ok, %{user: user}} <- Accounts.register_user(user_params, @profile_params) do
      user
    end
  end
end
