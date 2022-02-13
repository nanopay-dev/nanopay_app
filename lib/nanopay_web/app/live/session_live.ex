defmodule NanopayWeb.App.SessionLive do
  use NanopayWeb, :live_view_auth

  @impl true
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
    <form class="space-y-6" action="#" method="POST">
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

      <div class="flex items-center justify-between">
        <div class="flex items-center">
          <input id="remember-me" name="remember-me" type="checkbox"
            class="h-5 w-5 rounded text-indigo-500 bg-white bg-opacity-10 hover:bg-opacity-20 border-none focus:outline-none focus:ring-2 focus:ring-blue-400 focus:ring-opacity-30 focus:ring-offset-2 focus:ring-offset-slate-800 transition-colors">
          <label for="remember-me" class="block ml-2 text-sm text-gray-400"> Remember me </label>
        </div>

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

end
