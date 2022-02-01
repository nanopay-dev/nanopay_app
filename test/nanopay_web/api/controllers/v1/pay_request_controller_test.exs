defmodule NanopayWeb.API.V1.PayRequestControllerTest do
  use NanopayWeb.ConnCase
  import Nanopay.PaymentsFixtures

  @valid_params %{
    "description" => "Test payment",
    "satoshis" => 10_000,
    "ctx" => %{
      "outhash" => "fa5135922a40bfad366c0691fc1c37fd862afda18347ef94a47e82168690fd2b"
    }
  }

  @completion_params %{
    "txid" => "fa5135922a40bfad366c0691fc1c37fd862afda18347ef94a47e82168690fd2b"
  }

  setup %{conn: conn} do
    conn = conn
    |> put_req_header("accept", "application/json")
    |> put_req_header("content-type", "application/json")
    %{conn: conn}
  end

  describe "GET /v1/pay_requests/:id" do
    test "responds with the pay request", %{conn: conn} do
      pay_request = pay_request_fixture()
      assert %{"ok" => true, "data" => data} = conn
      |> get(Routes.v1_api_pay_request_path(conn, :show, pay_request.id))
      |> json_response(200)

      assert data["id"]
      assert data["status"] == "pending"
      assert data["description"] == @valid_params["description"]
      assert %{"amount" => "0.00010000", "currency" => "XSV"} = data["amount"]
      assert %{"amount" => "0.00005075", "currency" => "XSV"} = data["fee"]
    end

    test "responds with error when pay request doesnt exist", %{conn: conn} do
      assert %{"ok" => false, "error" => error} = conn
      |> get(Routes.v1_api_pay_request_path(conn, :show, "0d4c028b-200a-4484-aa08-91014164a96a"))
      |> json_response(404)

      assert error == "Not found"
    end
  end

  describe "POST /v1/pay_requests" do
    test "creates a payment request with valid params", %{conn: conn} do
      assert %{"ok" => true, "data" => data} = conn
      |> post(Routes.v1_api_pay_request_path(conn, :create), @valid_params)
      |> json_response(200)

      assert data["id"]
      assert data["status"] == "pending"
      assert data["description"] == @valid_params["description"]
      assert %{"amount" => "0.00010000", "currency" => "XSV"} = data["amount"]
      assert %{"amount" => "0.00005075", "currency" => "XSV"} = data["fee"]
    end

    test "responds with error with incorrect params", %{conn: conn} do
      assert %{"ok" => false, "errors" => errors} = conn
      |> post(Routes.v1_api_pay_request_path(conn, :create), %{})
      |> json_response(400)

      assert is_map(errors)
    end
  end

  describe "POST /v1/pay_requests/:id/complete" do
    test "completes a funded pay request and returns with signed inputs", %{conn: conn} do
      pay_request = pay_request_fixture(status: :funded)

      assert %{"ok" => true, "data" => data} = conn
      |> post(Routes.v1_api_pay_request_path(conn, :complete, pay_request.id), @completion_params)
      |> json_response(200)

      assert data["id"] == pay_request.id
      assert data["status"] == "completed"
    end

    #test "responds with error if preimage not given", %{conn: conn} do
    #  assert %{"ok" => false, "errors" => errors} = conn
    #  |> post(Routes.v1_api_pay_request_path(conn, :complete), %{})
    #  |> json_response(404)
    #
    #  assert is_map(errors)
    #end

    test "responds with error if payrequest is pending", %{conn: conn} do
      pay_request = pay_request_fixture(status: :pending)
      assert %{"ok" => false, "error" => error} = conn
      |> post(Routes.v1_api_pay_request_path(conn, :complete, pay_request.id), @completion_params)
      |> json_response(404)

      assert error == "Not found"
    end

    test "responds with error if payrequest is already complete", %{conn: conn} do
      pay_request = pay_request_fixture(status: :completed)
      assert %{"ok" => false, "error" => error} = conn
      |> post(Routes.v1_api_pay_request_path(conn, :complete, pay_request.id), @completion_params)
      |> json_response(404)

      assert error == "Not found"
    end
  end
end
