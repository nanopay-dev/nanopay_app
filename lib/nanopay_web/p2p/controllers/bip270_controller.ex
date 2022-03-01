defmodule NanopayWeb.P2P.Bip270Controller do
  use NanopayWeb, :controller
  alias Nanopay.Payments
  alias Nanopay.Payments.PayRequest

  action_fallback :handle_error

  @doc """
  GET /p2p/bip270/payment/:id

  Responds with Bip270 Payment Request
  """
  def show(conn, %{"id" => id}) do
    with %PayRequest{} = pay_request <- Payments.get_pay_request(id, status: :pending) do
      conn
      |> put_resp_header("content-type", "application/json; charset=utf-8")
      |> render(pay_request_template(conn), pay_request: pay_request)
    end
  end

  @doc """
  POST /p2p/bip270/payment/:id

  Recieves a transaction satisfying a PayRequest and responds with a Bip270
  Payment ACK.
  """
  def pay(conn, %{"id" => id, "transaction" => rawtx} = params) do
    with {:ok, tx} <- BSV.Tx.from_binary(rawtx, encoding: :hex),
         %PayRequest{} = pay_request <- Payments.get_pay_request(id, status: :pending),
         {:ok, %{pay_request: pay_request}} <- Payments.fund_pay_request_with_tx(pay_request, tx)
    do
      channel = "pr:#{ pay_request.id }"
      NanopayWeb.Endpoint.broadcast(channel, "payment", Map.get(pay_request, [:id, :status]))

      conn
      |> put_resp_header("content-type", "application/json; charset=utf-8")
      |> render(payment_template(conn), params: params)
    end
  end

  # Render the spec or handcash pay request template
  defp pay_request_template(conn) do
    headers = get_req_header(conn, "accept")
    case Enum.member?(headers, "application/bitcoinsv-paymentrequest") do
      true  -> "pay_request_bip270.json"
      false -> "pay_request_hc.json"
    end
  end

  # Render the spec or handcash payment template
  defp payment_template(conn) do
    headers = get_req_header(conn, "accept")
    case Enum.member?(headers, "application/bitcoinsv-paymentack") do
      true  -> "payment_bip270.json"
      false -> "payment_hc.json"
    end
  end

  # Fallback action - always respond with Bad Request
  defp handle_error(conn, _any) do
    conn
    |> put_status(400)
    |> render("error.json")
  end

end
