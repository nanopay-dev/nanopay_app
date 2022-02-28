defmodule NanopayWeb.App.FormComponent do
  use NanopayWeb, :component

  def select(assigns) do
    ~H"""
    <div class="relative" x-data="{isOpen: false}">
      <button
        type="button"
        class="relative w-full pl-3 pr-10 py-2 text-sm text-left bg-white bg-opacity-10 hover:bg-opacity-20 focus:bg-opacity-20 rounded-md shadow-sm cursor-default transition-colors"
        @click="isOpen = !isOpen">

        <span class="block truncate">Any status</span>
        <span class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
          <.icon name="chevron-down" class="fa w-3 h-3 text-gray-400" />
        </span>
        <%#= render_slot(@inner_block, List.first(@entries)) %>
      </button>

      <div
        class="absolute z-10 mt-2 w-full max-h-60 bg-slate-800 ring-2 ring-blue-400 ring-opacity-30 ring-offset-2 ring-offset-slate-800 overflow-auto shadow-lg rounded-md"
        x-show="isOpen"
        x-transition:enter=""
        x-transition:enter-start=""
        x-transition:enter-end=""
        x-transition:leave="transition-opacity ease-in duration-100"
        x-transition:leave-start="opacity-100"
        x-transition:leave-end="opacity-0"
        @click.away="isOpen = false">

        <ul class="py-1 bg-black bg-opacity-40">
          <%= for entry <- @entries do %>
            <!--
            Select option, manage highlight styles based on mouseenter/mouseleave and keyboard navigation.

            Highlighted: "text-white bg-indigo-600", Not Highlighted: "text-gray-900"
            -->
            <li class="relative py-2 pl-3 pr-9 text-white bg-white text-opacity-70 bg-opacity-0 hover:text-opacity-100 hover:bg-opacity-5 cursor-default select-none">
              <%= render_slot(@inner_block, entry) %>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end
end
