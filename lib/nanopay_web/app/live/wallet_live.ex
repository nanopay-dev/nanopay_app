defmodule NanopayWeb.App.WalletLive do
  use NanopayWeb, :live_view
  alias Nanopay.FiatWallet
  alias Nanopay.FiatWallet.Topup
  alias Nanopay.Coinbox
  alias Nanopay.Payments.PayRequest

  @impl true
  def mount(_params, _session, %{assigns: assigns} = socket) do
    balance = FiatWallet.get_user_balance(assigns.current_user)
    txns = FiatWallet.paginate_user_txns(assigns.current_user)

    socket = assign(socket, [
      balance: balance,
      txns: txns
    ])

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(%{assigns: assigns} = socket, :index, params) do
    txns = case Map.get(params, "page") do
      nil -> assigns.txns
      page -> FiatWallet.paginate_user_txns(assigns.current_user, page: page)
    end

    assign(socket, [
      page_title: "Wallet",
      txns: txns
    ])
  end

  defp apply_action(%{assigns: assigns} = socket, :show, %{"id" => id}) do
    txn = FiatWallet.get_user_txn(assigns.current_user, id)
    subject = txn.subject_type
    |> String.to_existing_atom()
    |> Nanopay.Repo.get(txn.subject_id)
    |> preload_subject_association()

    assign(socket, [
      page_title: txn.description,
      txn: txn,
      subject: subject
    ])
  end

  # TODO
  defp preload_subject_association(%PayRequest{} = pay_request),
    do: Nanopay.Repo.preload(pay_request, :used_coin)

  defp preload_subject_association(subject), do: subject

  @impl true
  def handle_event("topup", %{"topup" => type}, %{assigns: assigns} = socket) do
    with {:ok, topup} <- FiatWallet.create_user_topup(assigns.current_user, %{type: type}),
         {:ok, session} <- Stripe.Session.create(stripe_params(socket, topup))
    do
      {:noreply, redirect(socket, external: session.url)}
    else
      err ->
        IO.inspect {:err, err}
        {:noreply, socket}
    end
  end

  # TODO
  defp stripe_params(%{assigns: assigns} = socket, topup) do
    params = %{
      mode: "payment",
      payment_method_types: ["card"],
      success_url: Routes.app_topup_url(socket, :paid, topup.id) <> "?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: Routes.app_topup_url(socket, :cancelled, topup.id),
      client_reference_id: topup.id,
      line_items: Topup.get_line_items(topup)
    }

    case assigns.current_user.stripe_id do
      nil -> Map.put(params, :customer_email, assigns.current_user.email)
      customer_id -> Map.put(params, :customer, customer_id)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <div class="lg:col-span-2">
        <div class="p-6 md:p-8 bg-black bg-opacity-20 rounded-lg overflow-hidden">
          <h2 class="mb-2 text-base font-bold text-gray-300">Transactions</h2>

          <%= if Enum.empty?(@txns.entries) do %>
            <.empty_state
              title="No transactions"
              subtitle="Get started by topping up your wallet."
              icon="receipt">
              <.topup_btn label="Topup $10" topup="usd_10" />
            </.empty_state>
          <% else %>
            <div class="mb-6 overflow-x-scroll">
              <table class="min-w-full">
                <tbody class="divide-y divide-gray-700">
                  <%= for txn <- @txns.entries do %>
                    <tr>
                      <td class="w-full pr-4 py-3 whitespace-nowrap">
                        <div class="flex items-center">
                          <.txn_icon type={txn.subject_type} class="flex flex-shrink-0 items-center justify-center w-10 h-10 rounded-full overflow-hidden" />
                          <div class="ml-4">
                            <p class="text-sm font-medium text-gray-100 truncate"><%= txn.description %></p>
                            <time
                              datetime={txn.inserted_at}
                              class="text-sm text-gray-400">
                              <%= Timex.format!(txn.inserted_at, "{D} {Mfull} {YYYY}, {h24}:{m}") %>
                            </time>
                          </div>
                        </div>
                      </td>
                      <td class="px-4 py-3 whitespace-nowrap text-center text-sm font-medium">
                        <div class={"text-lg font-medium #{ ccy_color(txn.base_amount) }"}><%= txn.base_amount %></div>
                        <div class="text-xs text-gray-500"><%= Money.to_string!(txn.balance, fractional_digits: 4) %></div>
                      </td>
                      <td class="pl-4 py-3 whitespace-nowrap text-right text-sm font-medium">
                        <%= live_patch to: Routes.app_wallet_path(@socket, :show, txn.id),
                          class: "flex items-center justify-center h-9 w-9 text-gray-300 bg-white bg-opacity-5 hover:text-gray-100 hover:bg-opacity-20 rounded-full transition-colors" do %>
                          <.icon name="magnifying-glass" class="fa h-4 w-4" />
                        <% end %>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>

            <.pagination
              path={Routes.app_wallet_path(@socket, :index)}
              page_number={@txns.page_number}
              total_pages={@txns.total_pages} />
          <% end %>
        </div>
      </div>

      <div class="order-first lg:order-2">
        <div class="mb-5 bg-gradient-to-r from-green-400 to-cyan-500 rounded-lg overflow-hidden shadow">
          <div class="flex items-center p-4 lg:px-8 lg:py-6">
            <div>
              <.icon name="credit-card" family="regular" class="fa w-8 h-8 text-white text-opacity-75" />
            </div>
            <div class="flex-auto pl-4 lg:pl-8">
              <dt class="text-sm font-medium text-gray-100 truncate">Wallet balance</dt>
              <dd class="mt-1 text-3xl font-bold text-gray-100"><%= Money.to_string!(@balance, fractional_digits: 4) %></dd>
            </div>
          </div>
        </div>
        <div class="p-6 md:p-8 bg-black bg-opacity-20 rounded-lg overflow-hidden">
          <h2 class="mb-2 text-base font-bold text-gray-300">Topup</h2>
          <p class="text-sm text-gray-400">Phasellus at magna dignissim, consequat nisl eget, sagittis nisl.</p>
          <div class="flex lg:flex-col xl:flex-row mt-4 space-x-4 lg:space-x-0 lg:space-y-4 xl:space-x-4 xl:space-y-0">
            <.topup_btn label="Topup $10" topup="usd_10" />
            <.topup_btn label="Topup $20" topup="usd_20" />
          </div>
        </div>
      </div>

      <%= if @live_action == :show do %>
        <.txn_modal txn={@txn} subject={@subject} />
      <% end %>
    </div>
    """
  end

  defp txn_modal(assigns) do
    ~H"""
    <.live_component
      module={NanopayWeb.App.ModalComponent}
      id={"txn-#{ @txn.id }"}
      close-to={Routes.app_wallet_path(NanopayWeb.Endpoint, :index)}>

      <div class="flex items-center">
        <.txn_icon type={@txn.subject_type} class="flex flex-shrink-0 items-center justify-center w-10 h-10 rounded-full overflow-hidden" />
        <div class="flex-auto px-4">
          <p class="text-base font-medium text-gray-100 truncate"><%= @txn.description %></p>
          <time
            datetime={@txn.inserted_at}
            class="text-sm text-gray-400">
            <%= Timex.format!(@txn.inserted_at, "{D} {Mfull} {YYYY}, {h24}:{m}") %>
          </time>
        </div>
        <div class="flex-shrink-0">
          <span class={"text-lg font-medium #{ ccy_color(@txn.base_amount) }"}><%= Money.to_string!(@txn.base_amount, fractional_digits: 4) %></span>
        </div>
      </div>
      <div class="mt-4 pt-4 md:ml-14 border-t border-gray-700">
        <div class="overflow-x-scroll">
          <.subject_table subject={@subject} />
        </div>
      </div>

    </.live_component>
    """
  end

  # TODO
  defp subject_table(assigns) do
    ~H"""
    <table class="min-w-full">
      <tbody class="divide-y divide-gray-800">
        <.subject_rows subject={@subject} />
      </tbody>
    </table>
    """
  end

  # TODO
  defp subject_rows(%{subject: %Topup{}} = assigns)  do
    ~H"""
    <tr>
      <td class="py-2 pr-4 text-xs text-gray-500">Amount</td>
      <td class="py-2 pl-4 text-xs text-gray-400 text-right"><%= @subject.amount %></td>
    </tr>
    <tr>
      <td class="py-2 pr-4 text-xs text-gray-500">Service fee</td>
      <td class="py-2 pl-4 text-xs text-gray-400 text-right"><%= @subject.fee %></td>
    </tr>
    """
  end

  defp subject_rows(%{subject: %PayRequest{}} = assigns)  do
    assigns = case assigns.subject.used_coin do
      %Coinbox.Coin{} = coin ->
        address = coin
        |> Coinbox.Key.derive_pubkey()
        |> BSV.Address.from_pubkey()
        |> BSV.Address.to_string()

        assign(assigns, :address, address)

      nil ->
        assigns
    end

    ~H"""
    <%= unless is_nil(@subject.used_coin) do %>
      <tr>
        <td class="py-2 pr-4 text-xs text-gray-500">TXID</td>
        <td class="py-2 pl-4 text-xs text-gray-400 text-right">
          <a
            href={"https://whatsonchain.com/tx/#{ @subject.used_coin.spending_txid }"}
            target="_blank"
            class="inline-flex items-start font-mono text-blue-400 hover:text-pink-400 transition-colors">
            <%= trunc_txid(@subject.used_coin.spending_txid) %>
            <.icon name="external-link-alt" class="fa w-3 h-3 ml-1" />
          </a>
        </td>
      </tr>
      <tr>
        <td class="py-2 pr-4 text-xs text-gray-500">Address</td>
        <td class="py-2 pl-4 text-xs text-gray-400 text-right">
          <a
            href={"https://whatsonchain.com/address/#{ @address }"}
            target="_blank"
            class="inline-flex items-start font-mono text-blue-400 hover:text-pink-400 transition-colors">
            <%= @address %>
            <.icon name="external-link-alt" class="fa w-3 h-3 ml-1" />
          </a>
        </td>
      </tr>
    <% end %>
    <tr>
      <td class="py-2 pr-4 text-xs text-gray-500">Amount (BSV)</td>
      <td class="py-2 pl-4 text-xs text-gray-400 text-right"><%= @subject.amount %></td>
    </tr>
    <tr>
      <td class="py-2 pr-4 text-xs text-gray-500">Service fee (BSV)</td>
      <td class="py-2 pl-4 text-xs text-gray-400 text-right"><%= @subject.fee %></td>
    </tr>
    """
  end

  # TODO
  defp txn_icon(%{type: "Elixir.Nanopay.FiatWallet.Topup"} = assigns) do
    ~H"""
    <div class={"#{@class} bg-gradient-to-br from-green-400 to-cyan-500"}>
      <.icon name="credit-card" class="fa w-5 h-5 text-white" />
    </div>
    """
  end

  defp txn_icon(assigns) do
    ~H"""
    <div class={"#{@class} bg-gradient-to-r from-pink-500 to-rose-500"}>
      <.icon name="code" class="fa w-5 h-5 text-white" />
    </div>
    """
  end

  # TODO
  defp ccy_color(amount) do
    case Money.cmp(amount, Money.new(:USD, 0)) do
      -1 -> "text-rose-400"
      _ -> "text-green-300"
    end
  end

  # TODO
  defp trunc_txid(txid) do
    {a, _} = String.split_at(txid, 8)
    {_, b} = String.split_at(txid, -8)
    a <> "…" <> b
  end

end
