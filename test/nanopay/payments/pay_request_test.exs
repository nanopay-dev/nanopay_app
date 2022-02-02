defmodule Nanopay.Payments.PayRequestTest do
  use Nanopay.DataCase
  alias Nanopay.Payments.PayRequest

  @valid_params %{
    description: "Test payment",
    satoshis: 10_000,
    ctx: %{
      outhash: "fa5135922a40bfad366c0691fc1c37fd862afda18347ef94a47e82168690fd2b"
    }
  }

  describe "changeset/2" do
    test "changes are valid with valid params" do
      changes = PayRequest.changeset(%PayRequest{}, @valid_params)
      assert changes.valid?
    end

    test "changes are invalid with no required fields" do
      changes = PayRequest.changeset(%PayRequest{}, %{})
      refute changes.valid?
      assert %{satoshis: _} = errors_on(changes)
    end

    test "changes automatically set amount and fee from satoshis" do
      %{changes: changes} = PayRequest.changeset(%PayRequest{}, @valid_params)
      assert changes.amount == Money.new(:XSV, "0.00010000")
      assert Money.round(changes.fee) == Money.new(:XSV, "0.00005075")
    end

    test "changes automatically set random keypath" do
      %{changes: changes} = PayRequest.changeset(%PayRequest{}, @valid_params)
      assert byte_size(changes.keypath) > 1
    end

    test "minimum fee is 150 sats when floor factored in" do
      %{changes: changes} = PayRequest.changeset(%PayRequest{}, Map.put(@valid_params, :satoshis, 10))
      assert Money.cmp!(changes.fee, Money.new(:XSV, "0.00000150")) == 0
    end
  end

  describe "status_changeset/2" do
    @tag :pending
    test "puts timestamp if completed"
  end

  describe "get_total/2" do
    @tag :pending
    test "returns the total amount + fee of the pay request"

    @tag :pending
    test "returns the total of the pay request with currency conversion"
  end

  describe "get_ref/1" do
    @tag :pending
    test "returns a short reference based on the GUID"
  end

  describe "get_paymail/1" do
    @tag :pending
    test "returns a paymail address on the short ref"
  end

  describe "build_coins/1" do
    @tag :pending
    test "returns coins required to satisfy the payment request"
  end
end
