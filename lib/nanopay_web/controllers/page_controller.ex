defmodule NanopayWeb.PageController do
  @moduledoc """
  TODO
  """
  use NanopayWeb, :controller

  @doc """
  GET /

  Renders the homepage
  """
  def index(conn, _params) do
    render(conn, "home.html")
  end

end
