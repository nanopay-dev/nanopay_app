defmodule Nanopay.PaymentsTest do
  use Nanopay.DataCase
  alias Nanopay.Payments
  alias Nanopay.Payments.PayRequest
  alias Nanopay.Coinbox
  alias Nanopay.Coinbox.{Coin, Txn}
  alias Nanopay.FiatWallet

  import Nanopay.AccountsFixtures
  import Nanopay.FiatWalletFixtures
  import Nanopay.PaymentsFixtures

  describe "pay_requests" do
    test "get_pay_request/1 returns the pay request with given id" do
      %{id: pay_request_id} = pay_request_fixture()
      assert %{id: ^pay_request_id} = Payments.get_pay_request(pay_request_id)
    end

    test "get_pay_request/1 returns nil if pay request doesn't exist" do
      assert Payments.get_pay_request("3bc69c6e-51bb-4103-9179-e4a4cfaa027a") == nil
    end

    test "get_pay_request/2 returns the pay request with given id and clauses" do
      %{id: pay_request_id} = pay_request_fixture()
      assert %{id: ^pay_request_id} = Payments.get_pay_request(pay_request_id, status: :pending)
    end

    test "get_pay_request/2 returns nil if the clauses don't match" do
      %{id: pay_request_id} = pay_request_fixture()
      assert Payments.get_pay_request(pay_request_id, status: :funded) == nil
    end

    test "get_pay_request_by_ref/1 returns the pay request with given short ref" do
      %{id: pay_request_id} = pr = pay_request_fixture()
      ref = PayRequest.get_ref(pr)
      assert %{id: ^pay_request_id} = Payments.get_pay_request_by_ref(ref)
    end

    test "get_pay_request_by_ref/1 returns the pay request with given short ref and clauses" do
      %{id: pay_request_id} = pr = pay_request_fixture()
      ref = PayRequest.get_ref(pr)
      assert %{id: ^pay_request_id} = Payments.get_pay_request_by_ref(ref, status: :pending)
    end

    test "create_pay_request/1 creates a new payment request" do
      assert {:ok, %PayRequest{}} = Payments.create_pay_request(%{
        description: "Test",
        satoshis: 10_000,
        ctx: %{
          outhash: "79e8f02d3855591de6513f33a3d83a5d21009941838bae975daac7331f3639d6"
        }
      })
    end

    test "create_pay_request/1 returns error with invalid params" do
      assert {:error, %Ecto.Changeset{}} = Payments.create_pay_request(%{})
    end

    @tag :pending
    test "set_pay_request_status/2 sets status on pay request"

    @tag :pending
    test "set_pay_request_status/2 sets timestamp if completed"
  end

  describe "fund_pay_request_with_user_wallet/2" do
    setup do
      user = user_fixture()
      txn = fiat_txn_fixture(user)

      {:ok, _} = Coinbox.create_coins(
        [Coin.init(1, "999", 1000)],
        %Txn{txid: "0000000000000000000000000000000000000000000000000000000000000001", block: 5000, status: :pushed}
      )

      %{
        pay_request: pay_request_fixture(satoshis: 10),
        txn: txn,
        user: user
      }
    end

    test "funds the pay request and adjusts the user balance", ctx do
      assert {:ok, changes} = Payments.fund_pay_request_with_user_wallet(ctx.pay_request, ctx.user)
      assert %{fiat_txn: %FiatWallet.Txn{} = txn} = changes
      assert Money.sub!(txn.balance, txn.base_amount) |> Money.cmp!(ctx.txn.balance) == 0

      #assert %{change: %Coin{satoshis: chg_sats}} = changes
      #assert %{tx: %BSV.Tx{outputs: [chg]} = tx} = changes
      #assert length(tx.inputs) == 1
      #assert length(tx.outputs) == 1
      #assert chg_sats == chg.satoshis
      assert %{pay_request: %PayRequest{status: :funded}} = changes
    end

    @tag :pending
    test "returns error if the fiat wallet has insuffienct balance"
  end

  describe "complete_pay_request/2" do
    @tag :pending
    test "creates a coinbox txn with the given params and marks pay request as completed"
  end
end
