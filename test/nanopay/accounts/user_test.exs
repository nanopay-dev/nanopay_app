defmodule Nanopay.Accounts.UserTest do
  use Nanopay.DataCase
  alias Nanopay.Accounts.User

  @valid_auth_params %{
    email: "john@example.com",
    password: "a362fb1354c0a69cfd9802fc2738aeac79950b585189a4809221a31a28128bd0"
  }

  #describe "changeset/2" do
  #end

  describe "auth_changeset/2" do
    test "changes are valid with valid params" do
      changes = User.auth_changeset(%User{}, @valid_auth_params)
      assert changes.valid?
    end

    test "password is hashed on valid changeset" do
      changes = User.auth_changeset(%User{}, @valid_auth_params)
      assert Ecto.Changeset.get_change(changes, :password_hash)
    end

    test "changes are invalid with no required fields" do
      changes = User.auth_changeset(%User{}, %{})
      refute changes.valid?
      assert %{email: _, password_hash: _} = errors_on(changes)
    end

    test "changes are invalid with invalid email" do
      changes = User.auth_changeset(%User{}, %{email: "notemail"})
      refute changes.valid?
      assert %{email: _} = errors_on(changes)
    end

    test "changes are invalid if email exists" do
      User.auth_changeset(%User{}, @valid_auth_params) |> Repo.insert()

      assert {:error, changes} =
        User.auth_changeset(%User{}, %{email: "John@Example.com", password: "123"})
        |> Repo.insert()

      refute changes.valid?
      assert %{email: _} = errors_on(changes)
    end
  end
end
