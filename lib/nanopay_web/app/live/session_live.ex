defmodule NanopayWeb.App.SessionLive do
  use NanopayWeb, :live_view_auth

  @impl true
  def mount(_params, %{"current_user" => _user}, socket) do
    socket = push_redirect(socket, to: Routes.app_dashboard_path(socket, :show))
    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    socket = assign(socket, [
      page_title: "Sign in to your account",
      subtitle: raw("""
      No account yet?
      #{ safe_to_string live_patch("Sign up here", to: Routes.app_registration_path(socket, :create), class: "text-blue-400 hover:text-pink-400 transition-colors") }.
      """)
    ])
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <form
      id="login-user-form"
      class="space-y-6"
      phx-hook="AlpineHook"
      x-data="SessionForm()"
      @submit.prevent="submit()"
      novalidate>

      <div>
        <%= label :user, :email, "Email address", class: "block mb-1 text-sm text-gray-400" %>
        <div class="relative">
          <%= email_input :user, :email,
            class: "
              block w-full px-3 py-2
              text-sm text-white text-opacity-80 focus:text-opacity-100
              bg-white bg-opacity-10 hover:bg-opacity-20 focus:bg-opacity-20
              placeholder-gray-400
              focus:outline-none focus:ring-2 focus:ring-blue-400 focus:ring-opacity-30 focus:ring-offset-2 focus:ring-offset-slate-800
              rounded-md border-none shadow-sm transition-colors",
            x_model: "email" %>
        </div>
      </div>

      <div>
        <%= label :user, :password, class: "block mb-1 text-sm text-gray-400" %>
        <div class="relative">
          <%= password_input :user, :password,
            class: "
              block w-full px-3 py-2
              text-sm text-white text-opacity-80 focus:text-opacity-100
              bg-white bg-opacity-10 hover:bg-opacity-20 focus:bg-opacity-20
              placeholder-gray-400
              focus:outline-none focus:ring-2 focus:ring-blue-400 focus:ring-opacity-30 focus:ring-offset-2 focus:ring-offset-slate-800
              rounded-md border-none shadow-sm transition-colors",
            x_model: "password" %>
        </div>
      </div>

      <div class="flex items-center justify-between">
        <div class="text-sm">
          <a href="#" class="text-blue-400 hover:text-pink-400 transition-colors"> Forgot your password? </a>
        </div>
      </div>

      <div>
        <button
          type="submit"
          class="inline-flex items-center justify-center w-full px-4 py-3 text-sm font-medium text-white text-opacity-80 bg-indigo-600 hover:text-opacity-100 hover:bg-indigo-500 rounded-md transition-colors">
          Sign in
        </button>
      </div>
    </form>
    """
  end

  @impl true
  def handle_event("login", %{"success" => true}, socket) do
    socket = socket
    |> put_flash(:success, "Successfully logged in")
    |> redirect(to: Routes.app_dashboard_path(socket, :show))

    {:noreply, socket}
  end

  def handle_event("login", %{"success" => false}, socket) do
    socket = put_flash(socket, :error, "Invalid email or password")

    {:noreply, socket}
  end

end
