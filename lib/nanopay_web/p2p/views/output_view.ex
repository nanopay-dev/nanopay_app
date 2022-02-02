defmodule NanopayWeb.P2P.OutputView do
  use NanopayWeb, :view

  def render("output.json", %{output: coin}) do
    %{
      satoshis: coin.satoshis,
      script: coin.script
    }
  end

end
