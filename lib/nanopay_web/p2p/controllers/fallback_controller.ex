defmodule NanopayWeb.P2P.FallbackController do
  use Phoenix.Controller

  def call(conn, {:error, _}) do
    conn
    |> put_status(400)
    |> put_view(NanopayWeb.API.ErrorView)
    |> render("400.json")
  end

end
