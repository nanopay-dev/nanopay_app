defmodule NanopayWeb.PageController do
  use NanopayWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
