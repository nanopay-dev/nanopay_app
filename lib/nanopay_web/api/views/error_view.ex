defmodule NanopayWeb.API.ErrorView do
  use NanopayWeb, :view

  # If you want to customize a particular status code
  # for a certain format, you may uncomment below.
  # def render("500.json", _assigns) do
  #   %{errors: %{detail: "Internal Server Error"}}
  # end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.json" becomes
  # "Not Found".
  def template_not_found(template, _assigns) do
    %{
      ok: false,
      error: Phoenix.Controller.status_message_from_template(template)
    }
  end

  def render("changeset.json", %{changeset: changes}) do
    errors = Ecto.Changeset.traverse_errors(changes, &translate_error/1)
    %{
      ok: false,
      errors: errors
    }
  end

  def render("error.json", %{error: error}) do
    %{
      ok: false,
      error: error
    }
  end
end
