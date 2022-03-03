defmodule NanopayWeb.App.ButtonComponent do
  use NanopayWeb, :component

  def topup_btn(assigns) do
    ~H"""
    <button
      class="inline-flex items-center justify-center px-4 py-3 text-sm font-bold text-gray-100 bg-gradient-to-br from-green-500 to-cyan-600 hover:from-green-400 hover:to-cyan-500 rounded-md transition-colors cursor-pointer"
      phx-click="topup"
      phx-value-topup={@topup}>
      <.icon name="plus" class="fa w-4 h-4 mr-2" />
      <%= @label %>
    </button>
    """
  end

end
