defmodule NanopayWeb.App.RegistrationLive do
  use NanopayWeb, :live_view_auth
  alias Nanopay.Accounts

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, [
      page_title: "Register a Nanopay account",
      subtitle: raw("""
      Already have an account?
      #{ safe_to_string live_patch("Sign in here", to: Routes.app_session_path(socket, :create), class: "text-blue-400 hover:text-pink-400 transition-colors") }.
      """)
    ])
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <form
      id="register-user-form"
      class="space-y-4"
      phx-hook="AlpineHook"
      x-data="RegistrationForm()"
      @submit.prevent="submit()"
      novalidate>

      <div>
        <%= label :profile, :handle, "Username", class: "block mb-1 text-sm text-gray-400" %>
        <div class="relative">
          <%= text_input :profile, :handle,
            class: "
              block w-full px-3 py-2
              text-sm text-white text-opacity-80 focus:text-opacity-100
              bg-white bg-opacity-10 hover:bg-opacity-20 focus:bg-opacity-20
              placeholder-gray-400
              focus:outline-none focus:ring-2 focus:ring-blue-400 focus:ring-opacity-30 focus:ring-offset-2 focus:ring-offset-slate-800
              rounded-md border-none shadow-sm transition-colors
              ",
            "@blur": "handle.blurred = true",
            ":class": "{'ring-1 ring-red-400': handle.blurred && handle.error}",
            x_model: "handle.value" %>
          <template x-if="handle.blurred && handle.error">
            <div class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
              <.icon name="exclamation-triangle" class="fa w-5 h-5 text-red-400" />
            </div>
          </template>
        </div>
        <template x-if="handle.blurred && handle.error">
          <div class="mt-2 text-sm text-red-500" x-text="handle.error"></div>
        </template>
      </div>

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
            "@blur": "email.blurred = true",
            ":class": "{'ring-1 ring-red-400': email.blurred && email.error}",
            x_model: "email.value" %>
          <template x-if="email.blurred && email.error">
            <div class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
              <.icon name="exclamation-triangle" class="fa w-5 h-5 text-red-400" />
            </div>
          </template>
        </div>
        <template x-if="email.blurred && email.error">
          <div class="mt-2 text-sm text-red-500" x-text="email.error"></div>
        </template>
      </div>

      <div>
        <%= label :user, :password, "Password", class: "block mb-1 text-sm text-gray-400" %>
        <div class="relative">
          <%= password_input :user, :password,
            class: "
              block w-full px-3 py-2
              text-sm text-white text-opacity-80 focus:text-opacity-100
              bg-white bg-opacity-10 hover:bg-opacity-20 focus:bg-opacity-20
              placeholder-gray-400
              focus:outline-none focus:ring-2 focus:ring-blue-400 focus:ring-opacity-30 focus:ring-offset-2 focus:ring-offset-slate-800
              rounded-md border-none shadow-sm transition-colors",
            "@blur": "password.blurred = true",
            ":class": "{'ring-1 ring-red-400': password.blurred && password.error}",
            x_model: "password.value" %>
          <template x-if="password.blurred && password.error">
            <div class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
              <.icon name="exclamation-triangle" class="fa w-5 h-5 text-red-400" />
            </div>
          </template>
        </div>
        <template x-if="password.blurred && password.error">
          <div class="mt-2 text-sm text-red-500" x-text="password.error"></div>
        </template>
      </div>

      <div class="pt-4">
        <button
          type="submit"
          class="inline-flex items-center justify-center w-full px-4 py-3 text-sm font-medium text-white text-opacity-80 bg-indigo-600 hover:text-opacity-100 hover:bg-indigo-500 rounded-md transition-colors"
          :class="{'bg-gray-500 hover:bg-gray-500 cursor-not-allowed': !isValid()}"
          :disabled="!isValid()">
          Register
        </button>
      </div>
    </form>
    """
  end

  @impl true
  def handle_event("submit", %{"user" => user_params, "profile" => profile_params}, socket) do
    case Accounts.register_user(user_params, profile_params) do
      {:ok, _user} ->
        {:reply, %{success: true}, socket}

      {:error, _key, changes, _} ->
        errors = Ecto.Changeset.traverse_errors(changes, &translate_error/1)
        {:reply, %{errors: errors}, socket}
    end
  end

  def handle_event("login", _params, socket) do
    socket = socket
    |> put_flash(:success, "Successfully logged in")
    |> redirect(to: Routes.app_dashboard_path(socket, :show))

    {:noreply, socket}
  end

end
