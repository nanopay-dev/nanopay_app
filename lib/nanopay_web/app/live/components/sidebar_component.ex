defmodule NanopayWeb.App.SidebarComponent do
  use NanopayWeb, :component

  # TODO -
  def sidebar_sections(view) do
    [%{
      name: "Main menu",
      links: [ %{
          name: "Dashboard",
          icon: "table-columns",
          path: Routes.app_dashboard_path(NanopayWeb.Endpoint, :show),
          current: view == NanopayWeb.App.DashboardLive
        }, %{
          name: "Payments",
          icon: "receipt",
          path: Routes.app_payments_path(NanopayWeb.Endpoint, :index),
          current: view == NanopayWeb.App.PaymentsLive
        }, %{
          name: "Wallet",
          icon: "wallet",
          path: Routes.app_wallet_path(NanopayWeb.Endpoint, :index),
          current: view == NanopayWeb.App.WalletLive
        #}, %{
        #  name: "Connected apps",
        #  icon: "code",
        #  path: Routes.app_dashboard_path(NanopayWeb.Endpoint, :show),
        #  current: false
        }
      ]
    #} ,%{
    #  name: "Developer menu",
    #  links: [
    #    %{
    #      name: "Your apps",
    #      icon: "code",
    #      path: Routes.app_dashboard_path(NanopayWeb.Endpoint, :show),
    #      current: false
    #    }
    #  ]
    }]
  end

  def sidebar(assigns) do
    ~H"""
    <div x-data="{isOpen: false}">
      <!-- bg overlay -->
      <div
        class="md:hidden fixed z-20 inset-0 bg-black bg-opacity-50"
        :class="isOpen ? 'visible opacity-100' : 'hidden opacity-0'" />

      <!-- toggle button bg overlay -->
      <div class="md:hidden fixed z-10 inset-x-0 flex items-center justify-end h-12 px-4 bg-slate-800 bg-opacity-80 border-b border-gray-700 backdrop-blur-sm">
        <img
          src={Routes.static_path(NanopayWeb.Endpoint, "/images/icon.png")}
          class="w-6"
          alt="Nanopay" />
      </div>

      <!-- side menu -->
      <div class="fixed z-30 inset-y-0 flex flex-col w-64 transition-transform ease-in-out duration-300 bg-slate-800"
        :class="isOpen ? 'translate-x-0' : '-translate-x-full md:translate-x-0'">

        <div class="flex-1 flex flex-col min-h-0 bg-black bg-opacity-30">
          <div class="flex-1 flex flex-col pt-6 pb-4 overflow-y-auto">
            <div class="flex items-center flex-shrink-0 px-6 mb-8">
              <img
                src={Routes.static_path(NanopayWeb.Endpoint, "/images/logo.png")}
                class="h-8 w-auto"
                alt="Nanopay" />
            </div>
            <nav class="flex-1 px-4 space-y-1">
              <%= for section <- @sections do %>
                <.nav_section {section} />
              <% end %>
            </nav>
          </div>

          <div>
            <.user_menu
              current_user={@current_user}
              current_profile={@current_profile} />
          </div>
        </div>

        <div class="md:hidden absolute top-0 left-full flex items-center h-12 px-2">
          <button class="inline-block p-2 cursor-pointer text-gray-300 hover:text-pink-400 transition-colors"
            @click="isOpen = !isOpen">
            <.icon name="bars" class="fa w-6 h-6" />
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp user_menu(assigns) do
    ~H"""
    <div
      class="relative flex-shrink-0 flex bg-slate-700"
      x-data="{isOpen: false}">
      <a
        class="block w-full p-4 group hover:bg-white hover:bg-opacity-5 transition-colors cursor-pointer"
        @click="isOpen = !isOpen">
        <div class="flex items-center">
          <div>
            <.avatar profile={@current_profile} />
          </div>
          <div class="mx-3 flex-auto">
            <p class="text-sm font-medium text-white"><%= @current_profile.handle %></p>
            <p class="text-xs font-medium text-gray-300 group-hover:text-gray-200">View profile</p>
          </div>
          <div>
            <.icon name="chevron-up" class="fa w-3 h-3" />
          </div>
        </div>
      </a>

      <div
        class="absolute right-0 bottom-full w-56 -mb-2 -mr-2 origin-bottom-right bg-slate-800 ring-2 ring-blue-400 ring-opacity-30 ring-offset-2 ring-offset-slate-800 rounded-md shadow-lg"
        x-show="isOpen"
        x-transition:enter="transition duration-100 ease-out"
        x-transition:enter-start="transform scale-90 opacity-0"
        x-transition:enter-end="transform scale-100 opacity-100"
        x-transition:leave="transition duration-75 ease-in"
        x-transition:leave-start="transform scale-100 opacity-100"
        x-transition:leave-end="transform scale-90 opacity-0"
        @click.away="isOpen = false">

        <div class="bg-black bg-opacity-40 divide-y divide-gray-800">
          <div class="px-4 py-3">
            <p class="text-sm">Signed in as</p>
            <p class="text-sm font-medium truncate"><%= @current_user.email %></p>
          </div>
          <div class="py-1">
            <%= live_redirect to: Routes.app_account_path(NanopayWeb.Endpoint, :index),
              class: "flex items-center px-4 py-2 text-sm text-white bg-white text-opacity-70 bg-opacity-0 hover:text-opacity-100 hover:bg-opacity-5"
            do %>
              <span class="inline-block w-4 mr-3 ">
                <.icon name="gear" class="fa w-4 h-4" />
              </span>
              Account settings
            <% end %>
            <!--
            <a class="flex items-center px-4 py-2 text-sm text-white bg-white text-opacity-70 bg-opacity-0 hover:text-opacity-100 hover:bg-opacity-5 cursor-pointer">
              <span class="inline-block w-4 mr-3 ">
                <.icon name="question" class="fa w-4 h-4" />
              </span>
              Support
            </a>
            <a class="flex items-center px-4 py-2 text-sm text-white bg-white text-opacity-70 bg-opacity-0 hover:text-opacity-100 hover:bg-opacity-5 cursor-pointer">
              <span class="inline-block w-4 mr-3 ">
                <.icon name="book-open" class="fa w-4 h-4" />
              </span>
              Privacy
            </a>
            -->
          </div>
          <div class="py-1">
            <%= link to: Routes.app_auth_path(NanopayWeb.Endpoint, :delete),
              method: :delete,
              class: "flex items-center px-4 py-2 text-sm text-white bg-white text-opacity-70 bg-opacity-0 hover:text-opacity-100 hover:bg-opacity-5"
            do %>
              <span class="inline-block w-4 mr-3 ">
                <.icon name="arrow-right-from-bracket" class="fa w-4 h-4" />
              </span>
              Sign out
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp avatar(assigns) do
    # <img class="inline-block h-9 w-9 rounded-full" src="https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" alt="" />
    ~H"""
    <span class="flex flex-col items-center justify-center h-9 w-9 rounded-full bg-slate-200 border border-indigo-800">
      <span class="text-xl text-indigo-600 font-light"><%= String.at(@profile.handle, 0) |> String.upcase() %></span>
    </span>
    """
  end

  defp nav_section(assigns) do
    ~H"""
    <div class="mb-8">
      <h4 class="pl-2 mb-1 text-xs font-light leading-tight text-gray-500">
        <%= @name %>
      </h4>
      <%= for link <- @links do %>
        <.nav_link {link} />
      <% end %>
    </div>
    """
  end

  defp nav_link(assigns) do
    ~H"""
    <%= live_redirect to: @path, class: "group flex items-center mb-0.5 px-2 py-2 text-sm font-medium rounded-md bg-white transition-colors #{link_colors(@current)}" do %>
      <span class={"inline-block w-5 mr-3 #{icon_colors(@current)}"}>
        <.icon name={@icon} class="fa w-5 h-5" />
      </span>
      <%= @name %>
    <% end %>
    """
  end

  defp link_colors(true), do: "text-white bg-opacity-10"
  defp link_colors(false), do: "text-gray-300 bg-opacity-0 hover:bg-opacity-5 hover:text-white"

  defp icon_colors(true), do: "text-gray-300"
  defp icon_colors(false), do: "text-gray-500 group-hover:text-gray-200"

end
