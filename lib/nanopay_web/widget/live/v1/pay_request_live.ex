defmodule NanopayWeb.Widget.V1.PayRequestLive do
  use NanopayWeb, :live_view_widget
  alias Nanopay.Payments

  @pay_methods [
    %{name: "Nanopay", value: "nanopay", protocols: ["nanopay"]},
    %{name: "HandCash", value: "handcash", protocols: ["bip270"]},
    %{name: "Money Button", value: "moneybutton", protocols: ["moneybutton"]},
    %{name: "Relay", value: "relay", protocols: ["relayone", "paymail"]},
    %{name: "Simply Cash", value: "simplycash", protocols: ["bip270", "paymail"]},
    %{name: "Chainbow", value: "chainbow", protocols: ["bip270", "paymail"]},
    #%{name: "Dotwallet", value: "dotwallet", protocols: ["niy"]},
    #%{name: "Volt", value: "volt", protocols: ["niy"]},
    %{name: "Electrum SV", value: "electrumsv", protocols: ["bip270"]}
  ]

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    pay_request = Payments.get_pay_request(id)
    pay_methods = @pay_methods
    pay_method = List.first(pay_methods)
    pay_protocol = List.first(pay_method.protocols)

    socket = assign(socket, [
      page_title: "Widget",
      pay_request: pay_request,
      pay_methods: pay_methods,
      pay_method: pay_method,
      pay_protocol: pay_protocol
    ])
    {:ok, socket}
  end

  @impl true
  def handle_event("update", %{"pay_method" => value}, %{assigns: assigns} = socket) do
    pay_method = Enum.find(assigns.pay_methods, & &1.value == value)
    pay_protocol = case Enum.member?(pay_method.protocols, assigns.pay_protocol) do
      true -> assigns.pay_protocol
      false -> List.first(pay_method.protocols)
    end

    socket = socket
    |> assign(pay_method: pay_method, pay_protocol: pay_protocol)
    |> push_event("close", %{})

    {:noreply, socket}
  end

  def handle_event("update", %{"protocol" => protocol}, %{assigns: assigns} = socket) do
    protocol = case Enum.member?(assigns.pay_method.protocols, protocol) do
      true -> protocol
      false -> assigns.pay_protocol
    end

    {:noreply, assign(socket, :pay_protocol, protocol)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="pay-request"
      phx-hook="AlpineHook">

      <div class="p-4 border-b border-slate-700">
        <.pay_select options={@pay_methods} value={@pay_method} />
      </div>

      <div class="p-4">
        <.pay_summary class="mb-6" pay_request={@pay_request} />
        <.pay_method pay_method={@pay_method} protocol={@pay_protocol} />
      </div>

      <div class="px-4 pb-4 text-center">
        <button type="button" class="
          inline-flex items-center px-2.5 py-1.5 text-xs font-medium rounded
          text-red-500 bg-white bg-opacity-10 hover:text-red-400 hover:bg-opacity-20 transition-colors
          focus:ring-2 focus:ring-red-400 focus:ring-opacity-30 focus:ring-offset-2 focus:ring-offset-slate-800"
          @click="$store.iframe.postMessage('close')">
          Cancel
        </button>
      </div>
    </div>
    """
  end

  # TODO
  defp pay_select(assigns) do
    ~H"""
    <div
      class="relative"
      id="pay-select"
      phx-hook="AlpineHook"
      x-data={"{open: false, idx: -1, selectedIdx: #{Enum.find_index(@options, & &1.value == @value.value)}, opts: #{@options |> Enum.map(& &1.value) |> Jason.encode!}}"}
      x-init="$watch('selectedIdx', i => {
        $el.$hook.pushEvent('update', {pay_method:  opts[i]}, _ => open = false)
      })">

      <button
        type="button"
        class="relative w-full p-3 pr-10 bg-white bg-opacity-10 hover:bg-opacity-20 focus:bg-opacity-20 rounded-lg shadow-sm cursor-default transition-colors"
        @click="open = true"
        @keydown.enter.stop.prevent="selectedIdx = idx"
        @keydown.arrow-up.prevent="idx = idx <= 0 ? opts.length - 1 : idx - 1"
        @keydown.arrow-down.prevent="idx = idx >= opts.length - 1 ? 0 : idx + 1">
        <span class="flex items-center">
          <%= img_tag Routes.static_path(NanopayWeb.Endpoint, "/images/wallets/#{@value.value}.png"), class: "flex-shrink-0 h-8 w-8 mr-3 rounded" %>
          <div class="text-left leading-tight">
            <span class="block text-xs font-medium text-gray-400">Pay with</span>
            <span class="block text-md font-semibold truncate"><%= @value.name %></span>
          </div>
        </span>
        <span class="ml-3 absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
          <.icon name="chevron-down" class="fa w-4 h-4 text-gray-400" />
        </span>
      </button>

      <div class="absolute z-10 mt-2 w-full bg-slate-800 ring-2 ring-blue-400 ring-opacity-30 ring-offset-2 ring-offset-slate-800 overflow-auto shadow-lg rounded-md"
        x-show="open"
        x-transition:enter=""
        x-transition:enter-start=""
        x-transition:enter-end=""
        x-transition:leave="transition ease-in duration-100"
        x-transition:leave-start="opacity-100"
        x-transition:leave-end="opacity-0"
        @click.away="open = false">

        <ul class="py-1 bg-black bg-opacity-40">
          <%= for {opt, idx} <- Enum.with_index(@options) do %>
            <li class="relative py-2 pl-3 pr-9 text-white bg-white bg-opacity-0 hover:text-opacity-100 hover:bg-opacity-5"
              :class={"selectedIdx === #{idx} ? 'text-opacity-100' : 'text-opacity-70'"}
              @mouseenter={"idx = #{idx}"}
              @click={"selectedIdx = idx"}>
              <div class="flex items-center">
                <%= img_tag Routes.static_path(NanopayWeb.Endpoint, "/images/wallets/#{opt.value}.png"), class: "flex-shrink-0 h-6 w-6 mr-3 rounded" %>
                <span class="block truncate"
                  :class={"selectedIdx === #{idx} ? 'font-semibold' : 'font-normal'"}>
                  <%= opt.name %>
                </span>
              </div>

              <%= if opt.value == @value.value do %>
                <span class="absolute inset-y-0 right-0 flex items-center pr-4">
                  <.icon name="check" class="fa h-4 w-4" />
                </span>
              <% end %>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end

  # TODO
  defp pay_summary(assigns) do
    ~H"""
    <div class={@class}>
      <div class="mb-1 text-xs font-medium text-slate-400 truncate">
        <%= @pay_request.description %>
      </div>
      <div class="my-1 text-3xl font-semibold text-slate-100">
        <%= Money.mult!(@pay_request.base_rate, @pay_request.amount.amount) |> Money.to_string!(fractional_digits: 4) %>
      </div>

      <div class="flex items-end mt-3 mb-2">
        <span class="pr-3 text-xs font-medium text-slate-400">
          Service fee
        </span>
        <span class="flex-auto border-b border-dashed border-slate-700"></span>
        <span class="pl-4 text-sm font-semibold text-slate-200">
          <%= Money.mult!(@pay_request.base_rate, @pay_request.fee.amount) |> Money.to_string!(fractional_digits: 4) %>
        </span>
      </div>
      <div class="flex items-end">
        <span class="pr-3 text-xs font-medium text-slate-400">
          Total
        </span>
        <span class="flex-auto border-b border-dashed border-slate-700"></span>
        <span class="pl-4 text-sm font-semibold text-slate-200">
          <%= Money.mult!(@pay_request.base_rate, Decimal.add(@pay_request.amount.amount, @pay_request.fee.amount)) |> Money.to_string!(fractional_digits: 4) %>
        </span>
      </div>
    </div>
    """
  end

  # TODO
  defp pay_method(assigns) do
    ~H"""
    <div>
      <%= if show_protocol_bar?(@pay_method.protocols) do %>
        <div class="flex items-center justify-between mb-2">
          <div>
            <%= if length(@pay_method.protocols) > 1 do %>
              <.protocol_select value={@protocol} options={@pay_method.protocols} />
            <% end %>
          </div>
          <div
            class="flex flex-row-reverse"
            data-url={"#{@pay_method.value}.#{@protocol}"}
            x-data="PayMethodBtns">

            <a
              class="inline-flex items-center ml-2 text-xs font-medium text-blue-400 hover:text-pink-400 transition-colors cursor-pointer"
              x-show="isMobile"
              @click="openUrl()">
              <.icon name="external-link-alt" class="fa h-3 w-3 mr-1" />
              <span>Open</span>
            </a>

            <a
              class="inline-flex items-center ml-2 p-1 rounded-full text-xs font-medium text-blue-400 hover:text-pink-400 transition-colors cursor-pointer"
              x-show="true"
              @click="copyUrl">
              <.icon name="copy" family="regular" class="fa h-3 w-3 mr-1" />
              <span>Copy URL</span>
            </a>
          </div>
        </div>
      <% end %>

      <.pay_method_ui protocol={@protocol} />
    </div>
    """
  end

  defp protocol_select(assigns) do
    ~H"""
    <div
      id="protocol-select"
      class="relative"
      phx-hook="AlpineHook"
      x-data={"{open: false, idx: -1, opts: #{Jason.encode!(@options)}}"}
      @select="$el.$hook.pushEvent('update', {protocol: opts[$event.detail]}, _ => {
        open = false
        idx = -1
      })">

      <button
        type="button"
        class="inline-flex items-center px-2.5 py-1.5 text-xs font-medium bg-white bg-opacity-10 hover:bg-opacity-20 focus:bg-opacity-20 rounded shadow-sm cursor-default transition-colors"
        @click="open = true"
        @keydown.enter.stop.prevent="$dispatch('select', idx)"
        @keydown.arrow-up.prevent="idx = idx <= 0 ? opts.length - 1 : idx - 1"
        @keydown.arrow-down.prevent="idx = idx >= opts.length - 1 ? 0 : idx + 1">
        <span><%= @value %></span>
        <.icon name="chevron-down" class="fa -mr-1 ml-2 h-3 w-3 text-gray-400" />
      </button>

      <ul
        class="absolute z-5 mt-2 text-xs bg-slate-800 ring-2 ring-blue-400 ring-opacity-30 ring-offset-2 ring-offset-slate-800 overflow-auto shadow-lg rounded-md"
        x-show="open"
        x-transition:enter=""
        x-transition:enter-start=""
        x-transition:enter-end=""
        x-transition:leave="transition ease-in duration-100"
        x-transition:leave-start="opacity-100"
        x-transition:leave-end="opacity-0"
        @click.away="open = false">

        <%= for {opt, idx} <- Enum.with_index(@options) do %>
          <li class="relative py-2 pl-3 pr-9 text-white bg-white text-opacity-70 bg-opacity-0 hover:text-opacity-100 hover:bg-opacity-5 cursor-default select-none"
            @mouseenter={"idx = #{idx}"}
            @click="$dispatch('select', idx)">
            <span class="block truncate"><%= opt %></span>
            <%= if opt == @value do %>
              <span class="absolute inset-y-0 right-0 flex items-center pr-3">
                <.icon name="check" class="fa h-3 w-3" />
              </span>
            <% end %>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  defp pay_method_ui(%{protocol: "nanopay"} = assigns) do
    assigns = Map.put(assigns, :component_id, "btn-#{:rand.uniform(100000)}")
    ~H"""
    <div class="flex flex-col items-center justify-center h-48">

      <p class="text-xs text-slate-400 text-center">Swipe to confirm payment</p>
      <button
        class="mt-4 text-xs px-2 py-1 bg-gray-400 text-white rounded"
        phx-click="fund">
        Tap here actually
      </button>
    </div>
    """
  end

  defp pay_method_ui(%{protocol: "bip270"} = assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center h-48">
      <div
        id="pay-bip270"
        class="mb-4 p-2 mx-auto bg-slate-100 rounded"
        phx-hook="QrCode"
        data-url={"https://p2p.nanopay.cash/bip270/pr-1"}>
      </div>
      <p class="text-xs text-slate-400 text-center">Scan to confirm payment</p>
    </div>
    """
  end

  defp pay_method_ui(%{protocol: "paymail"} = assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center h-48">
      <div
        id="pay-paymail"
        class="mb-4 p-2 mx-auto bg-slate-100 rounded"
        phx-hook="QrCode"
        data-url={"https://p2p.nanopay.cash/bip270/pr-1"}>
      </div>
      <p class="text-xs text-slate-400 text-center">Scan to confirm payment</p>
    </div>
    """
  end

  defp pay_method_ui(%{protocol: "moneybutton"} = assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center h-48">
      <div class="relative h-12 mb-8">
        <div class="absolute z-0 top-0 left-0 right-0">
          <svg class="animate-spin h-6 w-6 mt-2 mx-auto text-indigo-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
        </div>

        <div
          id="pay-mb"
          class="relative mx-auto z-10 translate-x-11"
          phx-hook="MoneyButton"></div>
      </div>
      <p class="text-xs text-slate-400 text-center">Swipe to confirm payment</p>
    </div>
    """
  end

  defp pay_method_ui(%{protocol: "relayone"} = assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center h-48">
      <div class="relative h-12 mb-8">
        <div class="absolute z-0 top-0 left-0 right-0">
          <svg class="animate-spin h-6 w-6 mt-2 mx-auto text-indigo-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
        </div>

        <div
          id="pay-relay"
          class="relative mx-auto z-10"
          phx-hook="RelayOne"></div>
      </div>
      <p class="text-xs text-slate-400 text-center">Swipe to confirm payment</p>
    </div>
    """
  end

  defp pay_method_ui(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center h-48">
      <p class="text-xs text-slate-400 text-center">not yet implemented</p>
    </div>
    """
  end

  # TODO
  defp show_protocol_bar?(protocols) when length(protocols) > 1, do: true
  defp show_protocol_bar?([protocol]) when protocol in ["bip270", "paymail"], do: true
  defp show_protocol_bar?(_protocols), do: false



end
