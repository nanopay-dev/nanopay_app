defmodule Nanopay.Accounts.KeyDataTest do
  use Nanopay.DataCase
  alias Nanopay.Accounts.KeyData

  @valid_custodial_params %{
    rec_path: "e/123",
    enc_secret: "FSO4k+jC",
    enc_recovery: "O1jEamz/DxMe"
  }

  @valid_non_custodial_params %{
    status: :noncustodial,
    enc_secret: "FSO4k+jC",
  }

  describe "changeset/2" do
    test "changes default to custodial mode" do
      assert %{status: :custodial} = %KeyData{}
    end

    test "changes are valid with valid params" do
      assert %{valid?: true} = KeyData.changeset(%KeyData{}, @valid_custodial_params)
      assert %{valid?: true} = KeyData.changeset(%KeyData{}, @valid_non_custodial_params)
    end

    test "changes are invalid with no fields with custodial status" do
      changes = KeyData.changeset(%KeyData{}, %{})
      refute changes.valid?
      assert %{rec_path: _, enc_secret: _, enc_recovery: _} = errors_on(changes)
    end


    test "changes are invalid with no required fields with non custodial status" do
      changes = KeyData.changeset(%KeyData{status: :noncustodial}, %{})
      refute changes.valid?
      assert %{enc_secret: _} = errors_on(changes)
    end
  end
end
