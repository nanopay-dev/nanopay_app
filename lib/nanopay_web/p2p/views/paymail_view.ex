defmodule NanopayWeb.P2P.PaymailView do
  use NanopayWeb, :view
  alias Nanopay.Payments.PayRequest

  def render("capabilities.json", _) do
    %{
      "bsvalias" => "1.0",
      "capabilities" => %{
        # P2P Payment Destination
        "2a40af698840" => Routes.p2p_paymail_url(NanopayWeb.Endpoint, :payment_destination, "{alias}@{domain.tld}") |> URI.decode(),
        # P2P Transactions
        "5f1323cddf31" => Routes.p2p_paymail_url(NanopayWeb.Endpoint, :transactions, "{alias}@{domain.tld}") |> URI.decode()
      }
    }
  end

  def render("payment_destination.json", %{pay_request: pay_request}) do
    %{
      "outputs" => render_many(PayRequest.build_coins(pay_request), __MODULE__, "output.json", as: :coin),
      "reference" => pay_request.id
    }
  end

  def render("transactions.json", %{txn: txn}) do
    %{
      "txid" => txn.txid
    }
  end

  def render("output.json", %{coin: coin}) do
    %{
      "satoshis" => coin.satoshis,
      "script" => coin.script
    }
  end

end
