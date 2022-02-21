defmodule NanopayWeb.App.NotificationComponent do
  use NanopayWeb, :component

  def notifications(assigns) do
    ~H"""
    <div aria-live="assertive" class="fixed inset-0 flex items-end px-4 py-6 pointer-events-none sm:p-6 sm:items-start">
      <div class="w-full flex flex-col items-center space-y-4 sm:items-end">
        <%= for notification <- @notifications do %>
          <%= render_slot(@inner_block, notification) %>
        <% end %>
      </div>
    </div>
    """
  end

  def notify(assigns) do
    ~H"""
    <div
      class={"w-full max-w-sm bg-slate-800 rounded-lg shadow-lg overflow-hidden pointer-events-auto ring-2 #{ ring_color(@type) } ring-opacity-60 ring-offset-2 ring-offset-slate-800"}
      x-data="{show: false}"
      x-init="_ => {
        setTimeout(_ => show = true, 50)
        setTimeout(_ => show = false, 12000)
      }"
      x-show="show"
      x-transition:enter="transition duration-300 ease-out"
      x-transition:enter-start="opacity-0 -translate-x-6"
      x-transition:enter-end="opacity-100 translate-x-0"
      x-transition:leave="transition duration-300 ease-in"
      x-transition:leave-start="opacity-100"
      x-transition:leave-end="opacity-0">

      <div class="p-4 bg-black bg-opacity-30">
        <div class="flex items-start">
          <div class="flex-shrink-0">
            <.icon
              name={icon_type(@type)}
              class={"fa w-6 h-6 #{ icon_color(@type) }"} />
          </div>
          <div class="ml-3 w-0 flex-1 pt-0.5">
            <p class="text-sm font-medium text-gray-300"><%= @message %></p>
          </div>
          <div class="ml-4 flex-shrink-0 flex">
            <button class="rounded-md inline-flex text-gray-600 hover:text-gray-500"
              @click="show = false">
              <span class="sr-only">Close</span>
              <.icon name="times" class="fa w-5 h-5" />
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # TODO
  defp icon_type("success"), do: "check-circle"
  defp icon_type("info"), do: "info-circle"
  defp icon_type("error"), do: "exclamation-circle"

  # TODO
  defp icon_color("success"), do: "text-green-400"
  defp icon_color("info"), do: "text-blue-400"
  defp icon_color("error"), do: "text-red-400"

  # TODO
  defp ring_color("success"), do: "ring-green-400"
  defp ring_color("info"), do: "ring-blue-400"
  defp ring_color("error"), do: "ring-red-400"

end
