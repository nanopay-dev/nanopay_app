defmodule NanopayWeb.App.PaymentsLive do
  use NanopayWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, [
      page_title: "Payments"
    ])
  end

  defp apply_action(socket, :show, _params) do
    assign(socket, [
      page_title: "Txn"
    ])
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
              <tbody class="divide-y divide-gray-700">
                <%= for _i <- 1..2 do %>
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
                    <td class="px-6 py-4 whitespace-nowrap text-center">
                      <span class="px-3 inline-flex text-xs leading-6 font-semibold rounded-full bg-green-200 bg-opacity-20 text-green-200">Completed</span>
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap text-right text-sm font-medium">
                      <div class="text-sm font-medium text-gray-400">₿ 0.00327292</div>
                      <div class="text-sm text-gray-500">$ 0.02</div>
                    </td>
                    <td class="pl-4 py-3 whitespace-nowrap text-right text-sm font-medium">
                      <%= live_patch to: Routes.app_payments_path(@socket, :show, "foobar"),
                        class: "flex items-center justify-center h-9 w-9 text-gray-300 bg-white bg-opacity-5 hover:text-gray-100 hover:bg-opacity-20 rounded-full transition-colors" do %>
                        <.icon name="search" class="fa h-4 w-4" />
                      <% end %>
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
                    <td class="px-6 py-4 whitespace-nowrap text-center">
                      <span class="px-3 inline-flex text-xs leading-6 font-semibold rounded-full bg-green-200 bg-opacity-20 text-green-200">Completed</span>
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap text-right text-sm font-medium">
                      <div class="text-sm font-medium text-gray-400">₿ 0.00327292</div>
                      <div class="text-sm text-gray-500">$ 0.02</div>
                    </td>
                    <td class="pl-4 py-3 whitespace-nowrap text-right text-sm font-medium">
                      <%= live_patch to: Routes.app_payments_path(@socket, :show, "foobar"),
                        class: "flex items-center justify-center h-9 w-9 text-gray-300 bg-white bg-opacity-5 hover:text-gray-100 hover:bg-opacity-20 rounded-full transition-colors" do %>
                        <.icon name="search" class="fa h-4 w-4" />
                      <% end %>
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
                    <td class="px-6 py-4 whitespace-nowrap text-center">
                      <span class="px-3 inline-flex text-xs leading-6 font-semibold rounded-full bg-green-200 bg-opacity-20 text-green-200">Completed</span>
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap text-right text-sm font-medium">
                      <div class="text-sm font-medium text-gray-400">₿ 0.00327292</div>
                      <div class="text-sm text-gray-500">$ 0.02</div>
                    </td>
                    <td class="pl-4 py-3 whitespace-nowrap text-right text-sm font-medium">
                      <%= live_patch to: Routes.app_payments_path(@socket, :show, "foobar"),
                        class: "flex items-center justify-center h-9 w-9 text-gray-300 bg-white bg-opacity-5 hover:text-gray-100 hover:bg-opacity-20 rounded-full transition-colors" do %>
                        <.icon name="search" class="fa h-4 w-4" />
                      <% end %>
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
                    <td class="px-6 py-4 whitespace-nowrap text-center">
                      <span class="px-3 inline-flex text-xs leading-6 font-semibold rounded-full bg-green-200 bg-opacity-20 text-green-200">Completed</span>
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap text-right text-sm font-medium">
                      <div class="text-sm font-medium text-gray-400">₿ 0.00327292</div>
                      <div class="text-sm text-gray-500">$ 0.02</div>
                    </td>
                    <td class="pl-4 py-3 whitespace-nowrap text-right text-sm font-medium">
                      <%= live_patch to: Routes.app_payments_path(@socket, :show, "foobar"),
                        class: "flex items-center justify-center h-9 w-9 text-gray-300 bg-white bg-opacity-5 hover:text-gray-100 hover:bg-opacity-20 rounded-full transition-colors" do %>
                        <.icon name="search" class="fa h-4 w-4" />
                      <% end %>
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
                    <td class="px-6 py-4 whitespace-nowrap text-center">
                      <span class="px-3 inline-flex text-xs leading-6 font-semibold rounded-full bg-amber-200 bg-opacity-20 text-amber-200">Pending</span>
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap text-right text-sm font-medium">
                      <div class="text-sm font-medium text-gray-400">₿ 0.00327292</div>
                      <div class="text-sm text-gray-500">$ 0.02</div>
                    </td>
                    <td class="pl-4 py-3 whitespace-nowrap text-right text-sm font-medium">
                      <%= live_patch to: Routes.app_payments_path(@socket, :show, "foobar"),
                        class: "flex items-center justify-center h-9 w-9 text-gray-300 bg-white bg-opacity-5 hover:text-gray-100 hover:bg-opacity-20 rounded-full transition-colors" do %>
                        <.icon name="search" class="fa h-4 w-4" />
                      <% end %>
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
        <.payment_modal />
      <% end %>
    </div>
    """
  end

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

  defp payment_modal(assigns) do
    ~H"""
    <.live_component
      module={NanopayWeb.App.ModalComponent}
      id="payment.id-todo"
      close-to={Routes.app_payments_path(NanopayWeb.Endpoint, :index)}>

      <div class="flex items-center">
        <div class="flex flex-shrink-0 items-center justify-center w-10 h-10 rounded-full overflow-hidden bg-gradient-to-r from-pink-500 to-rose-500">
          <.icon name="code" class="fa w-5 h-5 text-white" />
        </div>
        <div class="flex-auto px-4">
          <p class="text-base font-medium text-gray-100 truncate">Twetch post</p>
          <p class="text-sm text-gray-400">7 February 2022</p>
        </div>
        <div class="flex-shrink-0">
          <span class="text-lg font-medium text-rose-400">-$0.02</span>
        </div>
      </div>
      <div class="mt-4 pt-4 md:ml-14 border-t border-gray-700">
        <div class="overflow-x-scroll">
          <table class="min-w-full">
            <tbody class="divide-y divide-gray-800">
              <tr>
                <td class="py-2 pr-4 text-xs text-gray-500">TXID</td>
                <td class="py-2 pl-4 text-xs text-gray-400 text-right">
                  <a href="#" class="inline-flex items-start font-mono text-blue-400 hover:text-pink-400 transition-colors">
                    770531b7&hellip;4a8a9c1f
                    <.icon name="external-link-alt" class="fa w-3 h-3 ml-1" />
                  </a>
                </td>
              </tr>
              <tr>
                <td class="py-2 pr-4 text-xs text-gray-500">Address</td>
                <td class="py-2 pl-4 text-xs text-gray-400 text-right">
                  <a href="#" class="inline-flex items-start font-mono text-blue-400 hover:text-pink-400 transition-colors">
                    18VWHjMt4ixHddPPbs6righWTs3Sg2QNcn
                    <.icon name="external-link-alt" class="fa w-3 h-3 ml-1" />
                  </a>
                </td>
              </tr>
              <tr>
                <td class="py-2 pr-4 text-xs text-gray-500">Amount (BSV)</td>
                <td class="py-2 pl-4 text-xs text-gray-400 text-right">₿ 0.00327292</td>
              </tr>
              <tr>
                <td class="py-2 pr-4 text-xs text-gray-500">Service fee (BSV)</td>
                <td class="py-2 pl-4 text-xs text-gray-400 text-right">₿ 0.00068240</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

    </.live_component>
    """
  end

end
