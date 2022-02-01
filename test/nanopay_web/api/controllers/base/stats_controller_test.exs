defmodule NanopayWeb.API.Base.StatsControllerTest do
  use NanopayWeb.ConnCase

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "GET /pool" do
    test "responds with stats for all pools", %{conn: conn} do
      assert %{"ok" => true, "data" => data} = conn
      |> get(Routes.base_api_stats_path(conn, :index))
      |> json_response(:ok)

      assert is_map(data["inbox"])
      assert is_map(data["pool"])
      assert is_map(data["used"])
    end
  end

end
