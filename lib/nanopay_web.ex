defmodule NanopayWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use NanopayWeb, :controller
      use NanopayWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: NanopayWeb

      import Plug.Conn
      import NanopayWeb.Gettext
      alias NanopayWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/nanopay_web/templates",
        namespace: NanopayWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView, layout: {NanopayWeb.App.LayoutView, "live.html"}

      unquote(view_helpers())
      unquote(liveview_helpers())
    end
  end

  def live_view_auth do
    quote do
      use Phoenix.LiveView, layout: {NanopayWeb.App.LayoutView, "auth.html"}

      unquote(view_helpers())
      unquote(liveview_helpers())
    end
  end

  def live_view_widget do
    quote do
      use Phoenix.LiveView, layout: {NanopayWeb.Widget.LayoutView, "live.html"}

      unquote(view_helpers())
      unquote(widget_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
      unquote(liveview_helpers())
    end
  end

  def component do
    quote do
      use Phoenix.Component

      unquote(view_helpers())
      import FontAwesome.LiveView
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import NanopayWeb.Gettext
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import LiveView and .heex helpers (live_render, live_patch, <.form>, etc)
      import Phoenix.LiveView.Helpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import NanopayWeb.ErrorHelpers
      import NanopayWeb.Gettext
      alias NanopayWeb.Router.Helpers, as: Routes
    end
  end

  defp liveview_helpers do
    quote do
      import NanopayWeb.App.ButtonComponent
      import NanopayWeb.App.FormComponent
      import NanopayWeb.App.PaginationComponent
      import FontAwesome.LiveView
    end
  end

  defp widget_helpers do
    quote do
      import FontAwesome.LiveView
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
