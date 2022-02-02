defmodule NanopayWeb.P2P.PaymailController do
  use NanopayWeb, :controller
  alias Nanopay.Payments
  alias Nanopay.Payments.PayRequest
  #alias Presto.Transactions
  #alias Presto.Payments.Invoice

  action_fallback :handle_error

  @doc """
  TODO
  """
  def capabilities(conn, _params) do
    render(conn, "capabilities.json")
  end


  @doc """
  TODO
  """
  def payment_destination(conn, %{"paymail" => paymail, "satoshis" => satoshis}) do
    with {:ok, ref} <- parse_paymail(paymail),
         %PayRequest{} = pay_request <- Payments.get_pay_request_by_ref(ref, status: :pending),
         %PayRequest{} = pay_request <- verify_amount(pay_request, satoshis)
    do
      render(conn, "payment_destination.json", pay_request: pay_request)
    end
  end


  @doc """
  TODO
  """
  def transactions(conn, %{
    "paymail" => paymail,
    "hex" => rawtx,
    "reference" => pay_request_id
  }) do
    with {:ok, ref} <- parse_paymail(paymail),
         {:ok, tx} <- BSV.Tx.from_binary(rawtx, encoding: :hex),
         %PayRequest{} = pay_request <- Payments.get_pay_request_by_ref(ref, status: :pending),
         %PayRequest{} = pay_request <- verify_pay_request_id(pay_request, pay_request_id),
         {:ok, %{txn: txn}} <- Payments.fund_pay_request_with_tx(pay_request, tx)
    do
      # TODO figure out a way of notifying the payrequest
      #%{insert_tx: tx, invoice_status: invoice} = changes
      #Task.async(Presto.Notifier, :invoice_status_changed, [invoice])

      render(conn, "transactions.json", txn: txn)
    end
  end

  # TODO
  defp parse_paymail(paymail) do
    case Regex.run(~r/\A(PR\-)?([^@\s]+)@([^@\s]+)\z/i, paymail) do
      [^paymail, _pre, short_id, _domain] -> {:ok, short_id}
      _ -> :error
    end
  end

  # TODO
  defp verify_amount(pay_request, satoshis) do
    {:XSV, total_sats, -8, _} = pay_request
    |> PayRequest.get_total()
    |> Money.to_integer_exp()

    if total_sats == satoshis, do: pay_request, else: :error
  end

  # TODO
  defp verify_pay_request_id(pay_request, pay_request_id) do
    if pay_request_id == pay_request.id, do: pay_request, else: :error
  end

  # Fallback action - always respond with Bad Request
  defp handle_error(conn, _any) do
    conn
    |> put_status(400)
    |> put_view(NanopayWeb.ErrorView)
    |> render("400.json")
  end

end
