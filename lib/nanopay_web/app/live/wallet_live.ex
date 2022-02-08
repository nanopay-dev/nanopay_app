defmodule NanopayWeb.App.WalletLive do
  use NanopayWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, [
      page_title: "Wallet"
    ])
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <div class="lg:col-span-2">
        <div class="p-6 md:p-8 bg-black bg-opacity-20 rounded-lg overflow-hidden">
          <h2 class="mb-2 text-base font-bold text-gray-300">Transactions</h2>

          <div class="mb-6 overflow-x-scroll">
            <table class="min-w-full">
              <tbody class=" divide-y divide-gray-700">
                <%= for _i <- 1..2 do %>
                  <tr>
                    <td class="w-full pr-4 py-3 whitespace-nowrap">
                      <div class="flex items-center">
                        <div class="flex flex-shrink-0 items-center justify-center w-10 h-10 rounded-full overflow-hidden bg-gradient-to-br from-green-400 to-cyan-500">
                          <.icon name="credit-card" class="fa w-5 h-5 text-white" />
                        </div>
                        <div class="ml-4">
                          <p class="text-sm font-medium text-gray-100 truncate">Top-up</p>
                          <p class="text-sm text-gray-400">7 February 2022</p>
                        </div>
                      </div>
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap text-center text-sm font-medium">
                      <div class="text-lg font-medium text-green-300">$10.00</div>
                      <div class="text-xs text-gray-500">$ 13.263</div>
                    </td>
                    <td class="pl-4 py-3 whitespace-nowrap text-right text-sm font-medium">
                      <a href="#" class="flex items-center justify-center h-9 w-9 text-gray-300 bg-white bg-opacity-5 hover:text-gray-100 hover:bg-opacity-20 rounded-full transition-colors">
                        <.icon name="search" class="fa h-4 w-4" />
                      </a>
                    </td>
                  </tr>
                  <tr>
                    <td class="w-full pr-4 py-3 whitespace-nowrap">
                      <div class="flex items-center">
                        <div class="flex flex-shrink-0 items-center justify-center w-10 h-10 rounded-full overflow-hidden bg-gradient-to-r from-pink-500 to-rose-500">
                          <.icon name="code" class="fa w-5 h-5 text-white" />
                        </div>
                        <div class="ml-4">
                          <p class="text-sm font-medium text-gray-100 truncate">Twetch post</p>
                          <p class="text-sm text-gray-400">7 February 2022</p>
                        </div>
                      </div>
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap text-center text-sm font-medium">
                      <div class="text-lg font-medium text-rose-400">-$0.02</div>
                      <div class="text-xs text-gray-500">$ 13.263</div>
                    </td>
                    <td class="pl-4 py-3 whitespace-nowrap text-right text-sm font-medium">
                      <a href="#" class="flex items-center justify-center h-9 w-9 text-gray-300 bg-white bg-opacity-5 hover:text-gray-100 hover:bg-opacity-20 rounded-full transition-colors">
                        <.icon name="search" class="fa h-4 w-4" />
                      </a>
                    </td>
                  </tr>
                  <tr>
                    <td class="w-full pr-4 py-3 whitespace-nowrap">
                      <div class="flex items-center">
                        <div class="flex flex-shrink-0 items-center justify-center w-10 h-10 rounded-full overflow-hidden bg-gradient-to-r from-pink-500 to-rose-500">
                          <.icon name="code" class="fa w-5 h-5 text-white" />
                        </div>
                        <div class="ml-4">
                          <p class="text-sm font-medium text-gray-100 truncate">Twetch post</p>
                          <p class="text-sm text-gray-400">7 February 2022</p>
                        </div>
                      </div>
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap text-center text-sm font-medium">
                      <div class="text-lg font-medium text-rose-400">-$0.02</div>
                      <div class="text-xs text-gray-500">$ 13.263</div>
                    </td>
                    <td class="pl-4 py-3 whitespace-nowrap text-right text-sm font-medium">
                      <a href="#" class="flex items-center justify-center h-9 w-9 text-gray-300 bg-white bg-opacity-5 hover:text-gray-100 hover:bg-opacity-20 rounded-full transition-colors">
                        <.icon name="search" class="fa h-4 w-4" />
                      </a>
                    </td>
                  </tr>
                  <tr>
                    <td class="w-full pr-4 py-3 whitespace-nowrap">
                      <div class="flex items-center">
                        <div class="flex flex-shrink-0 items-center justify-center w-10 h-10 rounded-full overflow-hidden bg-gradient-to-r from-pink-500 to-rose-500">
                          <.icon name="code" class="fa w-5 h-5 text-white" />
                        </div>
                        <div class="ml-4">
                          <p class="text-sm font-medium text-gray-100 truncate">Bitpost comment</p>
                          <p class="text-sm text-gray-400">6 February 2022</p>
                        </div>
                      </div>
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap text-center text-sm font-medium">
                      <div class="text-lg font-medium text-rose-400">-$0.05</div>
                      <div class="text-xs text-gray-500">$ 13.263</div>
                    </td>
                    <td class="pl-4 py-3 whitespace-nowrap text-right text-sm font-medium">
                      <a href="#" class="flex items-center justify-center h-9 w-9 text-gray-300 bg-white bg-opacity-5 hover:text-gray-100 hover:bg-opacity-20 rounded-full transition-colors">
                        <.icon name="search" class="fa h-4 w-4" />
                      </a>
                    </td>
                  </tr>
                  <tr>
                    <td class="w-full pr-4 py-3 whitespace-nowrap">
                      <div class="flex items-center">
                        <div class="flex flex-shrink-0 items-center justify-center w-10 h-10 rounded-full overflow-hidden bg-gradient-to-r from-pink-500 to-rose-500">
                          <.icon name="code" class="fa w-5 h-5 text-white" />
                        </div>
                        <div class="ml-4">
                          <p class="text-sm font-medium text-gray-100 truncate">Some 21e8 mystical shit</p>
                          <p class="text-sm text-gray-400">5 February 2022</p>
                        </div>
                      </div>
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap text-center text-sm font-medium">
                      <div class="text-lg font-medium text-rose-400">-$2.18</div>
                      <div class="text-xs text-gray-500">$ 13.263</div>
                    </td>
                    <td class="pl-4 py-3 whitespace-nowrap text-right text-sm font-medium">
                      <a href="#" class="flex items-center justify-center h-9 w-9 text-gray-300 bg-white bg-opacity-5 hover:text-gray-100 hover:bg-opacity-20 rounded-full transition-colors">
                        <.icon name="search" class="fa h-4 w-4" />
                      </a>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>

          <.pagination />
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
              <dd class="mt-1 text-3xl font-bold text-gray-100">$ 13.263</dd>
            </div>
          </div>
        </div>
        <div class="p-6 md:p-8 bg-black bg-opacity-20 rounded-lg overflow-hidden">
          <h2 class="mb-2 text-base font-bold text-gray-300">Topup</h2>
          <p class="text-sm text-gray-400">Phasellus at magna dignissim, consequat nisl eget, sagittis nisl.</p>
          <div class="flex lg:flex-col xl:flex-row mt-4 space-x-4 lg:space-x-0 lg:space-y-4 xl:space-x-4 xl:space-y-0">
            <.topup_btn label="Topup $10" />
            <.topup_btn label="Topup $20" />
          </div>
        </div>
      </div>
    </div>
    """
  end

end
