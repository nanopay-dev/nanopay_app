defmodule NanopayWeb.App.RegistrationLive do
  use NanopayWeb, :live_view_auth

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
    <form class="space-y-4" action="#" method="POST">
      <div>
        <label for="email" class="block mb-1 text-sm text-gray-400"> Username </label>
        <div class="mt-1">
          <input
            type="email"
            id="email"
            name="email"
            class="
              block w-full px-3 py-2
              text-sm text-white text-opacity-80 focus:text-opacity-100
              bg-white bg-opacity-10 hover:bg-opacity-20 focus:bg-opacity-20
              placeholder-gray-400
              focus:outline-none focus:ring-2 focus:ring-blue-400 focus:ring-opacity-30 focus:ring-offset-2 focus:ring-offset-slate-800
              rounded-md border-none shadow-sm transition-colors"
            autocomplete="email"
            required>
        </div>
      </div>

      <div>
        <label for="email" class="block mb-1 text-sm text-gray-400"> Email address </label>
        <div class="mt-1">
          <input
            type="email"
            id="email"
            name="email"
            class="
              block w-full px-3 py-2
              text-sm text-white text-opacity-80 focus:text-opacity-100
              bg-white bg-opacity-10 hover:bg-opacity-20 focus:bg-opacity-20
              placeholder-gray-400
              focus:outline-none focus:ring-2 focus:ring-blue-400 focus:ring-opacity-30 focus:ring-offset-2 focus:ring-offset-slate-800
              rounded-md border-none shadow-sm transition-colors"
            autocomplete="email"
            required>
        </div>
      </div>

      <div>
        <label for="password" class="block mb-1 text-sm text-gray-400"> Password </label>
        <div class="mt-1">
          <input
            type="password"
            id="password"
            name="password"
            class="
              block w-full px-3 py-2
              text-sm text-white text-opacity-80 focus:text-opacity-100
              bg-white bg-opacity-10 hover:bg-opacity-20 focus:bg-opacity-20
              placeholder-gray-400
              focus:outline-none focus:ring-2 focus:ring-blue-400 focus:ring-opacity-30 focus:ring-offset-2 focus:ring-offset-slate-800
              rounded-md border-none shadow-sm transition-colors"
            autocomplete="current-password"
            required>
        </div>
      </div>

      <div class="pt-4">
        <button
          type="submit"
          class="inline-flex items-center justify-center w-full px-4 py-3 text-sm font-medium text-white text-opacity-80 bg-indigo-600 hover:text-opacity-100 hover:bg-indigo-500 rounded-md transition-colors">
          Register
        </button>
      </div>
    </form>
    """
  end

end
