defmodule NanopayWeb.API.Base.FundingView do
  use NanopayWeb, :view

  def render("show.json", %{address: address, script: script}) do
    %{
      ok: true,
      data: %{
        address: address,
        script: script
      }
    }
  end

  def render("create.json", %{txn: txn}) do
    %{
      ok: true,
      data: %{txid: txn.txid}
    }
  end

end
