defmodule NanopayWeb.App.ModalComponent do
  use NanopayWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed inset-0 z-50 overflow-y-auto"
      id={@myself}
      phx-hook="AlpineHook"
      x-data="{isOpen: false}"
      x-init="() => {
        setTimeout(() => isOpen = true, 50)
        $watch('isOpen', isOpen => {
          if (isOpen === false) {
            setTimeout(() => $el.$hook.pushEventTo($el, 'close'), 150)
          }
        })
      }">

      <div class="flex items-center justify-center min-h-screen p-4 sm:pb-20">
        <!-- bg overlay -->
        <div
          class="absolute inset-0 -z-1 bg-black bg-opacity-60 transition-opacity duration-300"
          :class="isOpen ? 'visible opacity-1' : 'invisible opacity-0'" />

        <div class="w-full sm:max-w-xl bg-slate-800 rounded-lg overflow-hidden shadow-xl ring-4 ring-blue-300 ring-opacity-20 transition-all ease-in-out duration-300"
          x-show="isOpen"
          x-transition:enter="transition duration-400 ease-out"
          x-transition:enter-start="-translate-y-16 scale-75 opacity-0"
          x-transition:enter-end="translate-y-0 scale-100 opacity-100"
          x-transition:leave="transition duration-150 ease-in"
          x-transition:leave-start="translate-y-0 scale-100 opacity-100"
          x-transition:leave-end="-translate-y-8 scale-90 opacity-0"
          @click.away="isOpen = false">

          <div class="p-4 sm:p-6 lg:p-8 bg-black bg-opacity-30">
            <%= render_slot(@inner_block) %>
          </div>
          <div class="flex justify-end px-4 py-3 sm:px-6 bg-slate-800">
            <button
              class="inline-flex items-center justify-center px-4 py-3 text-sm font-medium text-white text-opacity-80 bg-white bg-opacity-5 hover:text-opacity-100 hover:bg-opacity-10 rounded-md transition-colors"
              @click="isOpen = false">
              Close
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("close", _params, socket) do
    socket = case socket.assigns do
      %{"close-to": path} ->
        push_patch(socket, to: path)

      _ ->
        socket
    end

    {:noreply, socket}
  end

end
