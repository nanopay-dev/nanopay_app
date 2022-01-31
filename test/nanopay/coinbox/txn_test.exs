defmodule Nanopay.Coinbox.TxnTest do
  use Nanopay.DataCase
  alias Nanopay.Coinbox.Txn

  @valid_txn_params %{
    txid: "46fd6b672daa0890c4239923f3a848fe1474cf4ea6801b57ec24e1ec7dd6629d"
  }

  describe "changeset/2" do
    test "changes are valid with valid params" do
      changes = Txn.changeset(%Txn{}, @valid_txn_params)
      assert changes.valid?
    end

    test "changes are invalid with no required fields" do
      changes = Txn.changeset(%Txn{}, %{})
      refute changes.valid?
      assert %{txid: _} = errors_on(changes)
    end
  end

  describe "from_bsv_tx/1" do
    @tag :pending
    test "Returns a Txn from the given BSV.Tx"
  end

  describe "from_bsv_tx_builder/1" do
    @tag :pending
    test "Returns a Txn from the given BSV.TxBuilder"
  end

end
