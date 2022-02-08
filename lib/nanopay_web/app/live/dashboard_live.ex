defmodule NanopayWeb.App.DashboardLive do
  use NanopayWeb, :live_view
  import FontAwesome.LiveView, only: [icon: 1]

  @impl true
  def render(assigns) do
    ~H"""
    <.stats class="mb-10" />

    <div class="bg-black bg-opacity-20 rounded-lg overflow-hidden">
      <div class="lg:flex px-6 py-8 md:px-8 md:py-10">
        <div class="flex flex-col justify-between mb-8 pb-8 border-b border-gray-700 lg:w-2/3 lg:pr-4 lg:mb-0 lg:pb-0 lg:border-b-0">
          <div>
            <h2 class="text-base font-bold text-gray-300">Wallet activity</h2>
            <div id="balance-chart" phx-hook="BalanceChart" />
          </div>
          <div class="flex space-x-4">
            <%= live_redirect to: "/", class: "inline-flex items-center justify-center mt-6 px-4 py-3 text-sm font-bold text-white bg-gradient-to-br from-green-500 to-cyan-600 hover:from-green-400 hover:to-cyan-500 rounded-md transition-colors" do %>
              <.icon name="plus" class="fa w-4 h-4 mr-2" />
              Topup $10
            <% end %>
            <%= live_redirect to: "/", class: "inline-flex items-center justify-center mt-6 px-4 py-3 text-sm font-bold text-white bg-gradient-to-br from-green-500 to-cyan-600 hover:from-green-400 hover:to-cyan-500 rounded-md transition-colors" do %>
              <.icon name="plus" class="fa w-4 h-4 mr-2" />
              Topup $20
            <% end %>
          </div>
        </div>

        <div class="flex flex-col justify-between lg:w-1/3 lg:pl-4">
          <div>
            <h2 class="mb-2 text-base font-bold text-gray-300">Recent transactions</h2>
            <ul class="space-y-4">
              <li>
                <h3 class="text-sm font-medium text-gray-400">Today</h3>
                <ul class="divide-y divide-white divide-opacity-10">
                  <li class="py-2 flex items-center">
                    <div class="flex flex-shrink-0 items-center justify-center w-10 h-10 rounded-full overflow-hidden bg-gradient-to-br from-green-400 to-cyan-500">
                      <.icon name="credit-card" class="fa w-5 h-5 text-white" />
                    </div>
                    <div class="flex-auto px-3 overflow-hidden">
                      <p class="text-sm font-medium text-gray-100 truncate">Top-up</p>
                      <p class="text-sm text-gray-400">7 February 2022</p>
                    </div>
                    <div class="flex-shrink-0">
                      <span class="text-sm text-green-400">$10.00</span>
                    </div>
                  </li>
                  <li class="py-2 flex items-center">
                    <div class="flex flex-shrink-0 items-center justify-center w-10 h-10 rounded-full overflow-hidden bg-gradient-to-r from-pink-500 to-rose-500">
                      <.icon name="code" class="fa w-5 h-5 text-white" />
                    </div>
                    <div class="flex-auto px-4 overflow-hidden">
                      <p class="text-sm font-medium text-gray-100 truncate">Twetch post</p>
                      <p class="text-sm text-gray-400">7 February 2022</p>
                    </div>
                    <div class="flex-shrink-0">
                      <span class="text-sm text-red-400">-$0.02</span>
                    </div>
                  </li>
                  <li class="py-2 flex items-center">
                    <div class="flex flex-shrink-0 items-center justify-center w-10 h-10 rounded-full overflow-hidden bg-gradient-to-r from-pink-500 to-rose-500">
                      <.icon name="code" class="fa w-5 h-5 text-white" />
                    </div>
                    <div class="flex-auto px-4 overflow-hidden">
                      <p class="text-sm font-medium text-gray-100 truncate">Twetch post</p>
                      <p class="text-sm text-gray-400">7 February 2022</p>
                    </div>
                    <div class="flex-shrink-0">
                      <span class="text-sm text-red-400">-$0.02</span>
                    </div>
                  </li>
                </ul>
              </li>
              <li>
                <h3 class="text-sm font-medium text-gray-400">Yesterday</h3>
                <ul class="divide-y divide-white divide-opacity-10">
                  <li class="py-2 flex items-center">
                    <div class="flex flex-shrink-0 items-center justify-center w-10 h-10 rounded-full overflow-hidden bg-gradient-to-r from-pink-500 to-rose-500">
                      <.icon name="code" class="fa w-5 h-5 text-white" />
                    </div>
                    <div class="flex-auto px-4 overflow-hidden">
                      <p class="text-sm font-medium text-gray-100 truncate">Bitpost comment</p>
                      <p class="text-sm text-gray-400">6 February 2022</p>
                    </div>
                    <div class="flex-shrink-0">
                      <span class="text-sm text-red-400">-$0.05</span>
                    </div>
                  </li>
                </ul>
              </li>
              <li>
                <h3 class="text-sm font-medium text-gray-400">Saturday, 5 February</h3>
                <ul class="divide-y divide-white divide-opacity-10">
                  <li class="py-2 flex items-center">
                    <div class="flex flex-shrink-0 items-center justify-center w-10 h-10 rounded-full overflow-hidden bg-gradient-to-r from-pink-500 to-rose-500">
                      <.icon name="code" class="fa w-5 h-5 text-white" />
                    </div>
                    <div class="flex-auto px-4 overflow-hidden">
                      <p class="text-sm font-medium text-gray-100 truncate">Some 21e8 mystical shit</p>
                      <p class="text-sm text-gray-400">5 February 2022</p>
                    </div>
                    <div class="flex-shrink-0">
                      <span class="text-sm text-red-400">-$2.18</span>
                    </div>
                  </li>
                </ul>
              </li>
            </ul>
          </div>

          <div class="mt-6">
            <%= live_redirect to: "/", class: "inline-flex items-center justify-center px-4 py-3 text-sm font-medium text-white text-opacity-80 bg-white bg-opacity-5 hover:text-opacity-100 hover:bg-opacity-10 rounded-md transition-colors" do %>
              <.icon name="search" class="fa w-4 h-4 mr-2" />
              View all transactions
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
      <dl class="mt-5 grid grid-cols-1 gap-5 sm:grid-cols-3">
        <div class="bg-gradient-to-r from-green-400 to-cyan-500 rounded-lg overflow-hidden shadow">
          <div class="flex items-center sm:flex-col sm:items-start lg:flex-row lg:items-center p-4 lg:px-8 lg:py-6">
            <div class="sm:mb-4 lg:-mb-0">
              <.icon name="credit-card" family="regular" class="fa w-8 h-8 text-white text-opacity-75" />
            </div>
            <div class="flex-auto pl-4 sm:pl-0 lg:pl-8">
              <dt class="text-sm font-medium text-gray-100 truncate">Wallet balance</dt>
              <dd class="mt-1 text-3xl sm:text-xl lg:text-2xl xl:text-3xl font-bold text-gray-100">$ 13.263</dd>
            </div>
          </div>
        </div>

        <div class="bg-gradient-to-r from-fuchsia-500 to-purple-600 rounded-lg overflow-hidden shadow">
          <div class="flex items-center sm:flex-col sm:items-start lg:flex-row lg:items-center p-4 lg:px-8 lg:py-6">
            <div class="sm:mb-4 lg:-mb-0">
              <.icon name="chart-line" family="regular" class="fa w-8 h-8 text-white text-opacity-75" />
            </div>
            <div class="flex-auto pl-4 sm:pl-0 lg:pl-8">
              <dt class="text-sm font-medium text-gray-100 truncate">30d transactions</dt>
              <dd class="mt-1 text-3xl sm:text-xl lg:text-2xl xl:text-3xl font-bold text-gray-100">483</dd>
            </div>
          </div>
        </div>

        <div class="bg-gradient-to-r from-pink-500 to-rose-500 rounded-lg overflow-hidden shadow">
          <div class="flex items-center sm:flex-col sm:items-start lg:flex-row lg:items-center p-4 lg:px-8 lg:py-6">
            <div class="sm:mb-4 lg:-mb-0">
              <.icon name="hand-holding-usd" family="regular" class="fa w-8 h-8 text-white text-opacity-75" />
            </div>
            <div class="flex-auto pl-4 sm:pl-0 lg:pl-8">
              <dt class="text-sm font-medium text-gray-100 truncate">Avg daily spend</dt>
              <dd class="mt-1 text-3xl sm:text-xl lg:text-2xl xl:text-3xl font-bold text-gray-100">$ 3.18</dd>
            </div>
          </div>
        </div>
      </dl>
    </div>
    """
  end

end
