defmodule NanopayWeb.API.V1.PayRequestView do
  use NanopayWeb, :view
  alias Nanopay.Payments.PayRequest

  def render("show.json", %{pay_request: pay_request}) do
    %{
      ok: true,
      data: render_one(pay_request, __MODULE__, "pay_request.json")
    }
  end

  def render("pay_request.json", %{pay_request: pr}) do
    %{
      id: pr.id,
      status: pr.status,
      amount: pr.amount,
      fee: pr.fee,
      description: pr.description,
      payment: %{
        paymail: PayRequest.get_paymail(pr),
        bip270_url: Routes.p2p_bip270_url(NanopayWeb.Endpoint, :show, pr.id)
      },
      created_at: pr.inserted_at,
      funded_at: pr.funded_at
    }
  end
end
