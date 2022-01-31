defmodule Nanopay.Payments.PayCtxTest do
  use Nanopay.DataCase
  alias Nanopay.Payments.PayCtx

  @valid_params %{
    outhash: "fa5135922a40bfad366c0691fc1c37fd862afda18347ef94a47e82168690fd2b"
  }

  describe "changeset/2" do
    test "changes are valid with valid params" do
      changes = PayCtx.changeset(%PayCtx{}, @valid_params)
      assert changes.valid?
    end

    test "changes are valid with valid version and locktime" do
      changes = PayCtx.changeset(%PayCtx{}, Map.merge(@valid_params, %{version: 1, locktime: 100_000}))
      assert changes.valid?
    end

    test "changes are invalid with no required fields" do
      changes = PayCtx.changeset(%PayCtx{}, %{})
      refute changes.valid?
      assert %{outhash: _} = errors_on(changes)
    end

    test "changes are invalid with invalid version and locktime" do
      changes = PayCtx.changeset(%PayCtx{}, Map.merge(@valid_params, %{version: -1, locktime: -1}))
      refute changes.valid?
      assert %{version: _, locktime: _} = errors_on(changes)
    end

    test "changes are invalid with invalid outhash" do
      changes = PayCtx.changeset(%PayCtx{}, %{outhash: "notouthash"})
      refute changes.valid?
      assert %{outhash: _} = errors_on(changes)
    end
  end

  describe "to_opts/1" do
    @tag :pending
    test "returns the pay ctx as a keyword list of options"
  end
end
