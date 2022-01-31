defmodule Nanopay.PaymentsFixtures do
  @moduledoc """
  This module defines test helpers for creating entities via the
  `Nanopay.Payments` context.
  """
  alias Nanopay.Payments

  @pay_request_params %{
    description: "Test payment",
    satoshis: 10_000,
    ctx: %{
      outhash: "79e8f02d3855591de6513f33a3d83a5d21009941838bae975daac7331f3639d6"
    }
  }

  @doc """
  Generate a pay request.
  """
  def pay_request_fixture(attrs \\ %{}) do
    pay_request_params = Enum.into(attrs, @pay_request_params)
    with {:ok, pay_request} <- Payments.create_pay_request(pay_request_params) do
      pay_request
    end
  end
end
