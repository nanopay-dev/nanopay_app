defmodule NanopayWeb.App.AppLive do
  import Phoenix.LiveView
  alias BSV.{PrivKey, PubKey}

  def on_mount(:default, _params, session, socket) do
    master_pubkey = Application.fetch_env!(:nanopay, :master_key)
    |> PrivKey.from_wif!()
    |> PubKey.from_privkey()
    |> PubKey.to_binary(encoding: :hex)

    socket = assign(socket, [
      master_pubkey: master_pubkey,
      current_user: Map.get(session, "current_user"),
      session_key: Map.get(session, "session_key")
    ])

    {:cont, socket}
  end
end
