defmodule NanopayWeb.API.V1.PayRequestView do
  use NanopayWeb, :view

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
        paymail: "TODO",
        bip270_url: "TODO",
        openpay_url: "TODO"
      },
      created_at: pr.inserted_at,
      completed_at: "TODO"
    }
  end
end
