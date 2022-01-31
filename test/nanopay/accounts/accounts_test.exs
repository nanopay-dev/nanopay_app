defmodule Nanopay.AccountsTest do
  use Nanopay.DataCase
  alias Nanopay.Accounts

  describe "users" do
    import Nanopay.AccountsFixtures

#    @invalid_attrs %{}

    test "get_user/1 returns the user with given id" do
      %{id: user_id} = user_fixture()
      assert %{id: ^user_id} = Accounts.get_user(user_id)
    end

    test "get_user/1 returns nil if user doesn't exist" do
      assert Accounts.get_user("3bc69c6e-51bb-4103-9179-e4a4cfaa027a") == nil
    end

    test "get_user_by_email/1 returns the user with given email" do
      %{email: email} = user_fixture()
      assert %{email: ^email} = Accounts.get_user_by_email(email)
      assert %{email: ^email} = Accounts.get_user_by_email(String.upcase(email))
    end

    test "get_user_by_email/1 returns nil if user doesn't exist" do
      assert Accounts.get_user_by_email("nothere@example.com") == nil
    end

    test "get_user_by_email_and_password/1 returns the user with given email" do
      %{email: email} = user_fixture(password: "testpassword")
      assert %{email: ^email} = Accounts.get_user_by_email_and_password(email, "testpassword")
    end

    test "get_user_by_email_and_password/1 returns nil password is incorrect" do
      %{email: email} = user_fixture()
      assert Accounts.get_user_by_email_and_password(email, "testpassword") == nil
    end

    @tag :pending
    test "register_user/1 with valid data returns user and profile"

    test "register_user/1 with invalid data returns error changeset" do
      assert {:error, :user, %Ecto.Changeset{}, _} = Accounts.register_user(%{}, %{})
    end
  end
end
