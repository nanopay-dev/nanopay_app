defmodule NanopayWeb.Widget.V1.PayRequestLive do
  use NanopayWeb, :live_view_widget
  alias Nanopay.Accounts.User
  alias Nanopay.FiatWallet
  alias Nanopay.Payments
  alias Nanopay.Payments.PayRequest

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
  def mount(%{"id" => id}, _session, %{assigns: assigns} = socket) do
    pay_methods = case assigns.current_user do
      %User{} -> @pay_methods
      nil     -> Enum.reject(@pay_methods, & &1.value == "nanopay")
    end
    pay_request = Payments.get_pay_request(id)
    pay_method = List.first(pay_methods)
    pay_protocol = List.first(pay_method.protocols)
    balance = FiatWallet.get_user_balance(assigns.current_user)

    # Subscribe to PR subsub
    channel = "pr:#{ pay_request.id }"
    NanopayWeb.Endpoint.subscribe(channel)

    socket = assign(socket, [
      page_title: "Widget",
      pay_request: pay_request,
      pay_methods: pay_methods,
      pay_method: pay_method,
      pay_protocol: pay_protocol,
      balance: balance
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

  def handle_event("fund", _params, %{assigns: assigns} = socket) do
    with %User{} = user <- assigns.current_user,
         {:ok, %{signed_txin: txin, txn: txn}} <- Payments.fund_pay_request_with_user_wallet(assigns.pay_request, user)
    do
      send(self(), %{event: "funded", payload: %{
        id: assigns.pay_request.id,
        txin: BSV.TxIn.to_binary(txin, encoding: :hex),
        parent: Base.encode16(txn.rawtx, case: :lower)
      }})

      {:noreply, socket}
    else
      {:error, :fiat_txn, _, _} ->
        # TODO show these errors to user
        IO.inspect "Insufficient fiat balance"
        {:noreply, socket}

      {:error, :tx, :coinbox_low, _} ->
        IO.inspect "Insufficient coinbox balance"
        {:noreply, socket}

      {:error, :coins, :cannot_fund_tx, _} ->
        IO.inspect "Unsure where this error even comes from"
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(%{event: "funded", payload: payload}, %{assigns: assigns} = socket) do
    if assigns.pay_request.status != :completed and assigns.pay_request.id == payload.id do
      pay_request = payload.id
      |> Payments.get_pay_request()
      |> set_payee(assigns.current_user)

      socket = socket
      |> assign(:pay_request, pay_request)
      |> push_event("funded", payload)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  # Sets payee on pay request
  defp set_payee(%PayRequest{} = pay_request, %User{} = user) do
    with {:ok, pay_request} <- Payments.set_pay_request_payee(pay_request, user) do
      pay_request
    end
  end

  defp set_payee(%PayRequest{} = pay_request, nil), do: pay_request

  @impl true
  def terminate(_reason, %{assigns: assigns}) do
    channel = "pr:#{ assigns.pay_request.id }"
    NanopayWeb.Endpoint.unsubscribe(channel)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="pay-request"
      phx-hook="AlpineHook"
      x-data="PayRequest">

      <div class="p-4 border-b border-slate-700">
        <.pay_select options={@pay_methods} value={@pay_method} />
      </div>

      <div class="p-4">
        <.pay_summary
          class="mb-6"
          pay_request={@pay_request} />
        <%= if @pay_request.status == :pending do %>
          <.pay_method
            pay_request={@pay_request}
            pay_method={@pay_method}
            protocol={@pay_protocol}
            balance={@balance} />
        <% else %>
          <.success_icon />
        <% end %>
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
  defp success_icon(assigns) do
    ~H"""
    <div class="text-center">
      <span class="text-sm font-semibold uppercase tracking-widest text-slate-500">Paid</span>
    </div>
    <div class="flex flex-col items-center justify-center h-48">
      <div class="sa-success">
        <div class="sa-success-tip"></div>
        <div class="sa-success-long"></div>
        <div class="sa-success-placeholder"></div>
        <div class="sa-success-fix"></div>
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
            data-url={pay_url(@protocol, @pay_request)}
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

      <.pay_method_ui pay_request={@pay_request} protocol={@protocol} balance={@balance} />
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

  defp pay_method_ui(%{protocol: "nanopay", balance: balance} = assigns) do
    has_balance = Money.cmp(balance, Money.new(balance.currency, 0)) == 1
    assigns = Map.put(assigns, :has_balance, has_balance)
    ~H"""
    <div class="flex flex-col items-center justify-center h-48 pb-6">
      <div class="flex items-center justify-center">
        <span class="pr-1 text-xs text-slate-400">
          Current balance
        </span>
        <span class={"pl-1 text-sm font-medium #{ balance_color(@has_balance) }"}>
          <%= @balance %>
        </span>
      </div>

      <button
        class={"inline-flex items-center justify-center w-64 my-4 px-4 py-3 text-sm font-bold text-gray-100 rounded-md #{ button_colors(@has_balance) }"}
        disabled={!@has_balance}
        phx-click="fund">
        <.icon name="dollar-sign" class="fa h-4 w-4 mr-1" />
        Pay
      </button>

      <p class="text-xs text-slate-400 text-center">
        <%= if @has_balance, do: "Tap to confirm payment", else: "Please select another payment method" %>
      </p>
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
        data-url={pay_url(@protocol, @pay_request)}>
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
        data-url={pay_url(@protocol, @pay_request)}>
      </div>
      <p class="text-xs text-slate-400 text-center">Scan to confirm payment</p>
    </div>
    """
  end

  defp pay_method_ui(%{protocol: "moneybutton"} = assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center h-48">
      <div class="relative h-12 mb-8">
        <div class="absolute z-0 inset-0 flex justify-center pt-2">
          <div class="h-7 w-7 animate-spin">
            <.icon name="circle-notch" class="fa h-7 w-7 text-blue-400" />
          </div>
        </div>

        <div
          id="pay-mb"
          class="relative mx-auto z-0 translate-x-11"
          phx-hook="MoneyButton"
          data-amount={PayRequest.get_total(@pay_request) |> Money.to_decimal()}
          data-paymail={PayRequest.get_paymail(@pay_request)} />
      </div>
      <p class="text-xs text-slate-400 text-center">Swipe to confirm payment</p>
    </div>
    """
  end

  defp pay_method_ui(%{protocol: "relayone"} = assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center h-48">
      <div class="relative h-12 mb-8">
        <div class="absolute z-0 inset-0 flex justify-center pt-2">
          <div class="h-7 w-7 animate-spin">
            <.icon name="circle-notch" class="fa h-7 w-7 text-blue-400" />
          </div>
        </div>

        <div
          id="pay-relay"
          class="relative mx-auto z-0"
          phx-hook="RelayOne"
          data-amount={PayRequest.get_total(@pay_request) |> Money.to_decimal()}
          data-paymail={PayRequest.get_paymail(@pay_request)} />
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

  # TODO
  defp pay_url("bip270", pay_request) do
    url = Routes.p2p_bip270_url(NanopayWeb.Endpoint, :show, pay_request.id)
    "pay:?r=#{ URI.encode(url, &URI.char_unreserved?/1) }"
  end

  defp pay_url("paymail", pay_request) do
    paymail = PayRequest.get_paymail(pay_request)
    {:XSV, satoshis, -8, _} = pay_request
    |> PayRequest.get_total()
    |> Money.to_integer_exp()

    "payto:#{ paymail }?amount=#{ satoshis }&purpose=#{ pay_request.description }"
  end

  defp pay_url(_, _), do: nil

  # TODO
  defp balance_color(true), do: "text-green-300"
  defp balance_color(_), do: "text-rose-400"

  # TODO
  defp button_colors(true), do: "bg-gradient-to-br from-green-500 to-cyan-600 hover:from-green-400 hover:to-cyan-500 transition-colors"
  defp button_colors(_), do: "bg-gray-500"


end
