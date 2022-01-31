defmodule Nanopay.FiatWallet.TxnTest do
  use Nanopay.DataCase
  alias Nanopay.FiatWallet.Txn
  import Nanopay.AccountsFixtures

  @valid_params %{
    description: "Test tx",
    base_amount: Money.new(:USD, 20),
    enc_recovery: "O1jEamz/DxMe"
  }

  describe "changeset/2" do
    test "changes default with prev balance of 0 and USD user ccy" do
      default = Money.new(:USD, 0)
      assert %{prev_balance: ^default, user_ccy: "USD"} = %Txn{}
    end

    test "changes are valid with valid params" do
      assert %{valid?: true} = Txn.changeset(%Txn{}, @valid_params)
    end

    test "changes are invalid with no required fields" do
      changes = Txn.changeset(%Txn{}, %{})
      refute changes.valid?
      assert %{description: _, base_amount: _} = errors_on(changes)
    end

    test "changes automatically set balance" do
      expected = Money.new(:USD, "35.00000")
      assert %{changes: %{balance: ^expected}} = Txn.changeset(%Txn{}, Map.put(@valid_params, :prev_balance, Money.new(:USD, 15)))
    end

    test "changes are invalid if balance is less than zero" do
      changes = Txn.changeset(%Txn{}, Map.put(@valid_params, :base_amount, Money.new(:USD, -20)))
      refute changes.valid?
      assert %{balance: _} = errors_on(changes)
    end

    test "changes put subject if given" do
      user = user_fixture()
      assert %{changes: changes} = Txn.changeset(%Txn{}, Map.put(@valid_params, :subject, user))
      assert changes.subject_type == "Elixir.Nanopay.Accounts.User"
      assert changes.subject_id == user.id
    end
  end
end
