defmodule Nanopay.Accounts.ProfileTest do
  use Nanopay.DataCase
  alias Nanopay.Repo
  alias Nanopay.Accounts.Profile

  @valid_params %{
    handle: "johndoe",
    pubkey: "03009910c3390271cd7500c4cb5571230228c1ccbb1ebced3e5f53b063172981cb",
    enc_privkey: "secretkey"
  }

  describe "changeset/2" do
    test "changes are valid with valid params" do
      changes = Profile.changeset(%Profile{}, @valid_params)
      assert changes.valid?
    end

    test "changes are invalid with no required fields" do
      changes = Profile.changeset(%Profile{}, %{})
      refute changes.valid?
      assert %{handle: _, pubkey: _, enc_privkey: _} = errors_on(changes)
    end

    test "changes are invalid with invalid handle" do
      changes = Profile.changeset(%Profile{}, Map.put(@valid_params, :handle, "Not Handle !"))
      refute changes.valid?
      assert %{handle: _} = errors_on(changes)
    end

    test "changes are invalid with invalid pubkey" do
      changes = Profile.changeset(%Profile{}, Map.put(@valid_params, :pubkey, "notpubkey"))
      refute changes.valid?
      assert %{pubkey: _} = errors_on(changes)
    end

    test "changes are invalid if handle exists" do
      Profile.changeset(%Profile{}, @valid_params) |> Repo.insert()

      assert {:error, changes} =
        Profile.changeset(%Profile{}, %{
          handle: "JohnDoe",
          pubkey: "032ce5207f088cc65482035c7c1aa71dfb515197ca68c7b39612b6b8ae11bb9664",
          enc_privkey: "secretkey"
        })
        |> Repo.insert()

      refute changes.valid?
      assert %{handle: _} = errors_on(changes)
    end

    test "changes are invalid if pubkey exists" do
      Profile.changeset(%Profile{}, @valid_params) |> Repo.insert()

      assert {:error, changes} =
        Profile.changeset(%Profile{}, %{
          handle: "JohnDoe2",
          pubkey: @valid_params.pubkey,
          enc_privkey: "secretkey"
        })
        |> Repo.insert()

      refute changes.valid?
      assert %{pubkey: _} = errors_on(changes)
    end
  end
end
