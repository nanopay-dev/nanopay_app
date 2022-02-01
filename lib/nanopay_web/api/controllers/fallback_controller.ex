defmodule NanopayWeb.API.FallbackController do
  use Phoenix.Controller

  def call(conn, {:error, %Ecto.Changeset{} = changes}) do
    conn
    |> put_status(400)
    |> put_view(NanopayWeb.API.ErrorView)
    |> render("changeset.json", changeset: changes)
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(404)
    |> put_view(NanopayWeb.API.ErrorView)
    |> render("error.json", error: "Not found")
  end

  def call(conn, {:error, :coins_not_found}) do
    conn
    |> put_status(400)
    |> put_view(NanopayWeb.API.ErrorView)
    |> render("error.json", error: "Funding output not found")
  end

  def call(conn, {:error, :invalid_pool}) do
    conn
    |> put_status(400)
    |> put_view(NanopayWeb.API.ErrorView)
    |> render("error.json", error: "Invalid pool channel")
  end

  def call(conn, {:error, :invalid_rawtx}) do
    conn
    |> put_status(400)
    |> put_view(NanopayWeb.API.ErrorView)
    |> render("error.json", error: "Invalid rawtx")
  end

end
