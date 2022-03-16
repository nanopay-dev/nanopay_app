defmodule NanopayWeb.App.PaymentsLive do
  use NanopayWeb, :live_view
  alias Nanopay.Payments
  alias Nanopay.Payments.PayRequest
  alias Nanopay.Coinbox

  @impl true
  def mount(_params, _session, %{assigns: assigns} = socket) do
    payments = Payments.paginate_user_payments(assigns.current_user)

    socket = assign(socket, [
      payments: payments
    ])

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(%{assigns: assigns} = socket, :index, params) do
    payments = case Map.get(params, "page") do
      nil -> assigns.payments
      page -> Payments.paginate_user_payments(assigns.current_user, page: page)
    end

    assign(socket, [
      page_title: "Payments",
      payments: payments
    ])
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    pay_request = Payments.get_pay_request(id)
    |> Nanopay.Repo.preload(:used_coin)

    assign(socket, [
      page_title: pay_request.description,
      payment: pay_request
    ])
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <div class="lg:col-span-2">
        <div class="p-6 md:p-8 bg-black bg-opacity-20 rounded-lg overflow-hidden">
          <h2 class="mb-2 text-base font-bold text-gray-300">Transactions</h2>

          <%= if Enum.empty?(@payments.entries) do %>
            <.empty_state
              title="No payments"
              subtitle="Payments to apps and services will be logged here."
              icon="receipt" />
          <% else %>

            <div class="mb-6 overflow-x-scroll">
              <table class="min-w-full">
                <tbody class="divide-y divide-gray-700">
                  <%= for payment <- @payments.entries do %>
                    <tr>
                      <td class="w-full pr-4 py-3 whitespace-nowrap">
                        <div class="flex items-center">
                          <.txn_icon pay_request={payment} class="flex flex-shrink-0 items-center justify-center w-10 h-10 rounded-full overflow-hidden" />
                          <div class="ml-4">
                            <p class="text-sm font-medium text-gray-100 truncate"><%= payment.description %></p>
                            <time
                              datetime={payment.inserted_at}
                              class="text-sm text-gray-400">
                              <%= Timex.format!(payment.inserted_at, "{D} {Mfull} {YYYY}, {h24}:{m}") %>
                            </time>
                          </div>
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-center">
                        <.status_badge status={payment.status} />
                      </td>
                      <td class="px-4 py-3 whitespace-nowrap text-right text-sm font-medium">
                        <div class="text-sm font-medium text-gray-400"><%= payment.amount %></div>
                        <div class="text-sm text-gray-500"><%= PayRequest.to_base_ccy(payment, :amount) |> Money.to_string!(fractional_digits: 4) %></div>
                      </td>
                      <td class="pl-4 py-3 whitespace-nowrap text-right text-sm font-medium">
                        <%= live_patch to: Routes.app_payments_path(@socket, :show, payment.id),
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
              path={Routes.app_payments_path(@socket, :index)}
              page_number={@payments.page_number}
              total_pages={@payments.total_pages} />
          <% end %>
        </div>
      </div>

      <div class="order-first lg:order-2">
        <div class="p-6 md:p-8 bg-black bg-opacity-20 rounded-lg">
          <h2 class="mb-2 text-base font-bold text-gray-300">Filter</h2>
          <p class="text-sm text-gray-400">Phasellus at magna dignissim, consequat nisl eget, sagittis nisl.</p>

          <div class="mt-4">
            <label class="block mb-1 text-sm text-gray-400">By status</label>
            <.select let={status} entries={~w(pending funded completed)}>
              <.status_option status={status} />
            </.select>
          </div>
        </div>
      </div>

      <%= if @live_action == :show do %>
        <.payment_modal payment={@payment} />
      <% end %>
    </div>
    """
  end

  # TODO
  defp payment_modal(assigns) do
    ~H"""
    <.live_component
      module={NanopayWeb.App.ModalComponent}
      id={"pmt-#{ @payment.id }"}
      close-to={Routes.app_payments_path(NanopayWeb.Endpoint, :index)}>

      <div class="flex items-center">
        <.txn_icon pay_request={@payment} class="flex flex-shrink-0 items-center justify-center w-10 h-10 rounded-full overflow-hidden" />
        <div class="flex-auto px-4">
          <p class="text-base font-medium text-gray-100 truncate"><%= @payment.description %></p>
          <time
            datetime={@payment.inserted_at}
            class="text-sm text-gray-400">
            <%= Timex.format!(@payment.inserted_at, "{D} {Mfull} {YYYY}, {h24}:{m}") %>
          </time>
        </div>
        <div class="flex-shrink-0">
          <span class="text-lg font-medium text-rose-400"><%= PayRequest.to_base_ccy(@payment, :amount) |> Money.to_string!(fractional_digits: 4) %></span>
        </div>
      </div>
      <div class="mt-4 pt-4 md:ml-14 border-t border-gray-700">
        <div class="overflow-x-scroll">
          <.payment_table payment={@payment} />
        </div>
      </div>

    </.live_component>
    """
  end

  # TODO
  defp payment_table(assigns) do
    assigns = case assigns.payment.used_coin do
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
    <table class="min-w-full">
      <tbody class="divide-y divide-gray-800">
        <%= unless is_nil(@payment.used_coin) do %>
          <tr>
            <td class="py-2 pr-4 text-xs text-gray-500">TXID</td>
            <td class="py-2 pl-4 text-xs text-gray-400 text-right">
              <a
                href={"https://whatsonchain.com/tx/#{ @payment.used_coin.spending_txid }"}
                target="_blank"
                class="inline-flex items-start font-mono text-blue-400 hover:text-pink-400 transition-colors">
                <%= trunc_txid(@payment.used_coin.spending_txid) %>
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
          <td class="py-2 pl-4 text-xs text-gray-400 text-right"><%= @payment.amount %></td>
        </tr>
        <tr>
          <td class="py-2 pr-4 text-xs text-gray-500">Service fee (BSV)</td>
          <td class="py-2 pl-4 text-xs text-gray-400 text-right"><%= @payment.fee %></td>
        </tr>
      </tbody>
    </table>
    """
  end

  # TODO
  defp status_badge(assigns) do
    ~H"""
    <span
      class={"px-3 inline-flex text-xs leading-6 font-semibold rounded-full bg-opacity-20 #{status_badge_colors(@status)}"}>
      <%= Phoenix.Naming.humanize(@status) %>
    </span>
    """
  end

  # TODO
  defp status_badge_colors(:pending), do: "text-amber-200 bg-amber-200"
  defp status_badge_colors(_), do: "text-green-200 bg-green-200"

  # TODO
  defp status_option(assigns) do
    colors = case assigns.status do
      "pending" -> "bg-amber-200 bg-opacity-20 text-amber-200"
      "funded" -> "bg-blue-200 bg-opacity-20 text-blue-200"
      "completed" -> "bg-green-200 bg-opacity-20 text-green-200"
    end

    assigns = assign(assigns, :colors, colors)

    ~H"""
    <div class="text-sm">
      <span class={"px-3 inline-flex text-xs leading-6 font-semibold rounded-full #{@colors}"}><%= @status %></span>
    </div>
    """
  end

  # TODO
  defp txn_icon(assigns) do
    ~H"""
    <div class={"#{@class} bg-gradient-to-r from-pink-500 to-rose-500"}>
      <.icon name="code" class="fa w-5 h-5 text-white" />
    </div>
    """
  end

  # TODO
  defp trunc_txid(txid) do
    {a, _} = String.split_at(txid, 8)
    {_, b} = String.split_at(txid, -8)
    a <> "…" <> b
  end

end
