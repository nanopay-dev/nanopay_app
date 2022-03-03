defmodule NanopayWeb.App.TopupController do
  @moduledoc """
  TODO
  """
  use NanopayWeb, :controller
  alias Nanopay.FiatWallet
  alias Nanopay.FiatWallet.Topup

  #action_fallback :handle_error

  @doc """
  GET /topup/:id/paid

  TODO
  """
  def paid(conn, %{"id" => id, "session_id" => session_id}) do
    with %Topup{} = topup <- FiatWallet.get_pending_topup(id),
         {:ok, %{payment_status: "paid"} = session} <- Stripe.Session.retrieve(session_id),
         {:ok, _topup} <- FiatWallet.topup_paid(topup, session)
    do
      conn
      |> put_flash(:success, "Topup successfully made")
      |> redirect(to: Routes.app_wallet_path(conn, :index))
    else
      _ ->
        {:error, :unauthenticated}
    end
  end

  @doc """
  GET /topup/:id/cancelled

  TODO
  """
  def cancelled(conn, %{"id" => id}) do
    with %Topup{} = topup <- FiatWallet.get_pending_topup(id),
         {:ok, _topup} <- FiatWallet.topup_cancelled(topup)
    do
      conn
      |> put_flash(:info, "Topup cancelled")
      |> redirect(to: Routes.app_wallet_path(conn, :index))
    end
  end

  ## Handles authentication errors
  #defp handle_error(conn, {:error, :unauthenticated}) do
  #  conn
  #  |> put_status(:unauthorized)
  #  |> put_view(NanopayWeb.ErrorView)
  #  |> render("error.json", error: %{title: "Unauthorized", detail: "Invalid email or password"})
  #end
end
