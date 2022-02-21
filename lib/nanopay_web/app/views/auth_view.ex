defmodule NanopayWeb.App.AuthView do
  use NanopayWeb, :view

  def render("session.json", %{session_key: session_key, user: user}) do
    %{
      session_key: session_key,
      secret_key: user.key_data.enc_secret
    }
  end
end
