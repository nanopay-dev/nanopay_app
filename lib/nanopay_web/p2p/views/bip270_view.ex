defmodule NanopayWeb.P2P.Bip270View do
  use NanopayWeb, :view
  alias Nanopay.Payments.PayRequest

  # Renders spec version of bip270
  def render("pay_request_bip270.json", %{pay_request: pay_request}) do
    %{
      "network" => "bitcoin",
      "memo" => pay_request.description,
      "outputs" => render_many(PayRequest.build_coins(pay_request), __MODULE__, "output.json", as: :coin),
      "creationTimestamp" => unix_timestamp(pay_request.inserted_at),
      "expirationTimestamp" => nil,
      "paymentUrl" => Routes.p2p_bip270_url(NanopayWeb.Endpoint, :pay, pay_request.id)
    }
  end

  def render("payment_bip270.json", %{params: params}) do
    %{
      "payment" => Map.take(params, ["merchantData", "transaction", "refundTo", "memo"]),
      "memo" => "Payment successful"
    }
  end

  # Renders handcash version of bip270
  def render("pay_request_hc.json", %{pay_request: pay_request}) do
    %{
      "network" => "bitcoin-sv",
      "memo" => pay_request.description,
      "outputs" => render_many(PayRequest.build_coins(pay_request), __MODULE__, "output.json", as: :coin),
      "creationTimestamp" => unix_timestamp(pay_request.inserted_at),
      "expirationTimestamp" => nil,
      "paymentUrl" => Routes.p2p_bip270_url(NanopayWeb.Endpoint, :pay, pay_request.id),
      "merchantData" => merchant_data(pay_request)
    }
  end

  def render("payment_hc.json", _), do: %{"success" => true}

  def render("error.json", %{}) do
    %{
      "memo" => "Bad Request",
      "error" => 1
    }
  end

  def render("output.json", %{coin: coin}) do
    %{
      "amount" => coin.satoshis,
      "script" => coin.script
    }
  end

  # Returns merchant data as a string
  defp merchant_data(_) do
    Jason.encode!(%{
      "avatarUrl" => Routes.static_url(NanopayWeb.Endpoint, "/images/icon.jpg"),
      "merchantName" => "Paypresto"
    })
  end

  # Returns unix timestamp
  defp unix_timestamp(datetime),
    do: datetime |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix()



end
