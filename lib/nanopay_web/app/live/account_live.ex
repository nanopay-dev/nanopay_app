defmodule NanopayWeb.App.AccountLive do
  use NanopayWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, [
      page_title: "Account"
    ])
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h4 class="mb-2 text-lg font-bold">Todo</h4>
    <ul class="list-disc pl-4">
      <li>Mange profile (username and avatar)</li>
      <li>Security (change email, password - and other stuff later)</li>
    </ul>
    """
  end

end
