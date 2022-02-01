defmodule NanopayWeb.API.V1.PayRequestController do
  @moduledoc """
  TODO
  """
  use NanopayWeb, :controller
  use OpenApiSpex.ControllerSpecs
  alias NanopayWeb.API.Schemas
  alias Nanopay.Payments

  action_fallback NanopayWeb.API.FallbackController

  @doc """
  TODO
  """
  operation :show,
    summary: "Get PayRequest",
    parameters: [
      id: [in: :path, description: "PayRequest ID", type: :string]
    ],
    responses: %{
      200 => {"PayRequest response", "application/json", Schemas.PayRequest.Response},
      400 => {"Bad request parameters", "application/json", Schemas.Errors.BadRequest},
    }
  def show(conn, %{"id" => id}) do
    with %{} = pay_request <- Payments.get_pay_request(id) do
      render(conn, "show.json", pay_request: pay_request)
    else
      _ -> {:error, :not_found}
    end
  end

  @doc """
  TODO
  """
  operation :create,
    summary: "Create new PayRequest",
    request_body: {"PayRequest params", "application/json", Schemas.PayRequest.Params},
    responses: %{
      200 => {"PayRequest response", "application/json", Schemas.PayRequest.Response},
      400 => {"Bad request parameters", "application/json", Schemas.Errors.BadRequest},
    }
  def create(conn, params) do
    with {:ok, pay_request} <- Payments.create_pay_request(params) do
      render(conn, "show.json", pay_request: pay_request)
    end
  end

  @doc """
  TODO
  """
  operation :complete,
    summary: "Complete PayRequest",
    parameters: [
      id: [in: :path, description: "PayRequest ID", type: :string]
    ],
    #request_body: {"PayRequest params", "application/json", PayRequest.Params},
    responses: %{
      200 => {"PayRequest response", "application/json", Schemas.PayRequest.Response},
      400 => {"Bad request parameters", "application/json", Schemas.Errors.BadRequest},
    }
  def complete(conn, %{"id" => id} = params) do
    with %{} = pay_request <- Payments.get_pay_request(id, status: :funded),
         {:ok, %{pay_request: pay_request}} <- Payments.complete_pay_request(pay_request, params)
    do
      render(conn, "show.json", pay_request: pay_request)
    else
      _err ->
        {:error, :not_found}
    end
  end

end
