defmodule NanopayWeb.App.AuthControllerTest do
  use NanopayWeb.ConnCase
  import Nanopay.AccountsFixtures
  alias NanopayWeb.App.Auth

  setup %{conn: conn} do
    conn = conn
    |> put_req_header("accept", "application/json")
    |> put_req_header("content-type", "application/json")
    %{conn: conn}
  end

  describe "POST /auth" do
    test "authenticates a user with correct params", %{conn: conn} do
      %{email: email, password: password, key_data: keydata} = user_fixture()
      res = conn
      |> post(Routes.app_auth_path(conn, :create), %{"email" => email, "password" => password})
      |> json_response(:created)

      assert res["secret_key"] == keydata.enc_secret
      assert res["session_key"]
    end

    test "responds with error with incorrect params", %{conn: conn} do
      %{email: email} = user_fixture()
      assert %{"ok" => false, "error" => error} = conn
      |> post(Routes.app_auth_path(conn, :create), %{"email" => email, "password" => "wrongpass"})
      |> json_response(:unauthorized)

      assert error == "Invalid email or password"
    end
  end

  describe "DELETE /auth" do
    test "destroys the session", %{conn: conn} do
      # Creates the user session first
      user = user_fixture()
      session_key = Auth.generate_session_key()
      token = Auth.generate_token(user, session_key)

      session = conn
      |> Plug.Test.init_test_session(%{})
      |> put_session(:user_token, token)
      |> delete(Routes.app_auth_path(conn, :delete))
      |> get_session()

      refute Map.has_key?(session, "user_token")
      assert get_in(session, ["phoenix_flash", "info"]) == "Successfully signed out"
    end
  end
end
