defmodule Nanopay.FiatWalletFixtures do
  @moduledoc """
  This module defines test helpers for creating entities via the
  `Nanopay.FiatWallet` context.
  """
  alias Nanopay.FiatWallet
  alias Nanopay.Accounts.User

  @txn_params %{
    description: "Test tx",
    base_amount: Money.new(:USD, 20)
  }

  @doc """
  Generate a Fiat Txn for a given user.
  """
  def fiat_txn_fixture(%User{} = user, attrs \\ %{}) do
    txn_params = Enum.into(attrs, @txn_params)
    %FiatWallet.Txn{}
    |> FiatWallet.Txn.changeset(txn_params)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Nanopay.Repo.insert!()
  end
end
