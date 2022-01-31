defmodule Nanopay.FiatWallet.TopupTest do
  use Nanopay.DataCase
  alias Nanopay.FiatWallet.Topup

  @valid_params %{
    type: "usd_10"
  }

  describe "changeset/2" do
    test "changes default with status of 0" do
      assert %{status: :pending} = %Topup{}
    end

    test "changes are valid with valid params" do
      assert %{valid?: true} = Topup.changeset(%Topup{}, @valid_params)
    end

    test "changes are invalid with no required fields" do
      changes = Topup.changeset(%Topup{}, %{})
      refute changes.valid?
      assert %{type: _, amount: _, fee: _} = errors_on(changes)
    end

    test "changes automatically set template params" do
      assert %{changes: changes} = Topup.changeset(%Topup{}, %{type: "usd_20"})
      assert changes.amount == Money.new(:USD, 20)
      assert changes.fee == Money.new(:USD, 3)
    end
  end

  describe "get_line_items/1" do
    @tag :pending
    test "returns stripe line item params for the given topup"
  end
end
