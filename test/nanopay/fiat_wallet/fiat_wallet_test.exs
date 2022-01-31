defmodule Nanopay.FiatWalletTest do
  use Nanopay.DataCase
  alias Nanopay.FiatWallet
  alias Nanopay.FiatWallet.Topup

  describe "topups" do
    import Nanopay.AccountsFixtures

    @tag :pending
    test "get_topup/1 gets a topup by its id"

    @tag :pending
    test "get_topup/1 returns nil if topud doesnt exist"

    @tag :pending
    test "get_pending_topup/1 gets a pending topup by its id"

    @tag :pending
    test "get_pending_topup/1 returns nil if topud doesnt exist"

    test "create_user_topup/1 with valid data returns topup" do
      user = user_fixture()
      assert {:ok, %Topup{}} = FiatWallet.create_user_topup(user, %{type: "usd_20"})
    end

    test "create_user_topup/1 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = FiatWallet.create_user_topup(user, %{})
    end

    @tag :pending
    test "topup_paid/2 sets the topup as paid and creates a txn"

    @tag :pending
    test "topup_cancelled/1 sets the topup as cencelled"

    @tag :pending
    test "get_user_balance/1 sets the user wallet balance"

    @tag :pending
    test "get_user_balance/1 defaults to 0 of no previous transactions"
  end
end
