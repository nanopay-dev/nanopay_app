defmodule NanopayWeb.App.DashboardLive do
  use NanopayWeb, :live_view
  alias Nanopay.Payments
  alias Nanopay.Payments.PayRequest

  @impl true
  def mount(_params, _session, %{assigns: assigns} = socket) do
    latest_payments = assigns.current_user
    |> Payments.latest_user_payments()
    |> Enum.group_by(& DateTime.to_date(&1.funded_at))
    |> Enum.reverse()

    stats = Payments.user_payment_stats(assigns.current_user)

    socket = assign(socket, [
      page_title: "Dashboard",
      latest_payments: latest_payments,
      stats: stats
    ])
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.stats class="mb-10" {stats_summary @stats} />

    <div class="bg-black bg-opacity-20 rounded-lg overflow-hidden">
      <div class="lg:flex px-6 py-8 md:px-8 md:py-10">
        <div class="flex flex-col justify-between mb-8 pb-8 border-b border-gray-700 lg:w-2/3 lg:pr-4 lg:mb-0 lg:pb-0 lg:border-b-0">
          <div>
            <h2 class="text-base font-bold text-gray-300">Payment trends</h2>
            <div id="payment-chart" phx-hook="PaymentChart" data-stats={Enum.slice(@stats, -14, 14) |> Jason.encode!()} />
          </div>
          <!--<div class="flex space-x-4">

          </div>-->
        </div>

        <div class="flex flex-col justify-between lg:w-1/3 lg:pl-4">
          <div>
            <h2 class="mb-2 text-base font-bold text-gray-300">Recent payments</h2>
            <%= if Enum.empty?(@latest_payments) do %>
              <.empty_state title="No payments yet" icon="receipt" />
            <% else %>
              <ul class="space-y-4">
                <%= for {date, payments} <- @latest_payments do %>
                  <li>
                    <h3 class="text-sm font-medium text-gray-400"><%= formatted_date(date) %></h3>
                    <ul class="divide-y divide-gray-700">
                      <%= for payment <- payments do %>
                        <li class="py-2 flex items-center">
                          <.txn_icon pay_request={payment} class="flex flex-shrink-0 items-center justify-center w-10 h-10 rounded-full overflow-hidden" />
                          <div class="flex-auto px-3 overflow-hidden">
                            <p class="text-sm font-medium text-gray-100 truncate"><%= payment.description %></p>
                            <time
                              datetime={payment.funded_at}
                              class="text-sm text-gray-400">
                              <%= Timex.format!(payment.funded_at, "{D} {Mfull} {YYYY}, {h24}:{m}") %>
                            </time>
                          </div>
                          <div class="flex-shrink-0">
                            <div class="text-sm font-medium text-gray-400">
                              <%= PayRequest.to_base_ccy(payment, :amount) |> Money.to_string!(fractional_digits: 4) %>
                            </div>
                          </div>
                        </li>
                      <% end %>
                    </ul>
                  </li>
                <% end %>
              </ul>
            <% end %>
          </div>

          <div class="mt-6">
            <%= live_redirect to: Routes.app_payments_path(@socket, :index),
              class: "inline-flex items-center justify-center px-4 py-3 text-sm font-medium text-white text-opacity-80 bg-white bg-opacity-5 hover:text-opacity-100 hover:bg-opacity-10 rounded-md transition-colors" do %>
              <.icon name="magnifying-glass" class="fa w-4 h-4 mr-2" />
              View all payments
            <% end %>
          </div>

        </div>
      </div>
    </div>
    """
  end

  defp stats(assigns) do
    ~H"""
    <div class={@class}>
      <dl class="mt-5 grid grid-cols-1 sm:grid-cols-3 gap-6">
        <div class="bg-gradient-to-r from-green-400 to-cyan-500 rounded-lg overflow-hidden shadow">
          <div class="flex items-center sm:flex-col sm:items-start lg:flex-row lg:items-center p-4 lg:px-8 lg:py-6">
            <div class="sm:mb-4 lg:-mb-0">
              <.icon name="credit-card" family="regular" class="fa w-8 h-8 text-white text-opacity-75" />
            </div>
            <div class="flex-auto pl-4 sm:pl-0 lg:pl-8">
              <dt class="text-sm font-medium text-gray-100 truncate">30d spend</dt>
              <dd class="mt-1 text-3xl sm:text-xl lg:text-2xl xl:text-3xl font-bold text-gray-100"><%= Money.to_string!(@amount, fractional_digits: 4) %></dd>
            </div>
          </div>
        </div>

        <div class="bg-gradient-to-r from-fuchsia-500 to-purple-600 rounded-lg overflow-hidden shadow">
          <div class="flex items-center sm:flex-col sm:items-start lg:flex-row lg:items-center p-4 lg:px-8 lg:py-6">
            <div class="sm:mb-4 lg:-mb-0">
              <.icon name="chart-line" family="regular" class="fa w-8 h-8 text-white text-opacity-75" />
            </div>
            <div class="flex-auto pl-4 sm:pl-0 lg:pl-8">
              <dt class="text-sm font-medium text-gray-100 truncate">30d payments</dt>
              <dd class="mt-1 text-3xl sm:text-xl lg:text-2xl xl:text-3xl font-bold text-gray-100"><%= @payments %></dd>
            </div>
          </div>
        </div>

        <div class="bg-gradient-to-r from-pink-500 to-rose-500 rounded-lg overflow-hidden shadow">
          <div class="flex items-center sm:flex-col sm:items-start lg:flex-row lg:items-center p-4 lg:px-8 lg:py-6">
            <div class="sm:mb-4 lg:-mb-0">
              <.icon name="hand-holding-dollar" family="regular" class="fa w-8 h-8 text-white text-opacity-75" />
            </div>
            <div class="flex-auto pl-4 sm:pl-0 lg:pl-8">
              <dt class="text-sm font-medium text-gray-100 truncate">Avg daily spend</dt>
              <dd class="mt-1 text-3xl sm:text-xl lg:text-2xl xl:text-3xl font-bold text-gray-100"><%= Money.to_string!(@average, fractional_digits: 4) %></dd>
            </div>
          </div>
        </div>
      </dl>
    </div>
    """
  end

  # TODO
  defp stats_summary(stats) do
    amount = stats
    |> Enum.map(& &1.amount)
    |> Enum.reduce(Decimal.new(0), & Decimal.add(&2, &1))
    |> Money.new(:USD)

    payments = stats
    |> Enum.map(& &1.payments)
    |> Enum.sum()

    %{
      amount: amount,
      payments: payments,
      average: Money.div!(amount, length(stats))
    }
  end

  # TODO
  defp formatted_date(date) do
    case Date.diff(Date.utc_today(), date) do
      0 -> "Today"
      1 -> "Yesterday"
      days -> "#{ days } days ago"
    end
  end

  # TODO
  defp txn_icon(assigns) do
    ~H"""
    <div class={"#{@class} bg-gradient-to-r from-pink-500 to-rose-500"}>
      <.icon name="code" class="fa w-5 h-5 text-white" />
    </div>
    """
  end

end
