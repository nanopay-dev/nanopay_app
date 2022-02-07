defmodule NanopayWeb.App.DashboardLive do
  use NanopayWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <p class="">Hello dashboard</p>
    """
  end

end
