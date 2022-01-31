defmodule Nanopay.Payments.FeesTest do
  use Nanopay.DataCase
  alias Nanopay.Payments.Fees

  describe "calc_pay_request/2" do
    test "returns the correct fees for the given amount" do
      # Compares with google spreadsheet results
      assert Fees.calc_pay_request(Money.new(:USD, "0.01")) |> Money.round(currency_digits: 3) == Money.new(:USD, "0.005")
      assert Fees.calc_pay_request(Money.new(:USD, "0.05")) |> Money.round(currency_digits: 3) == Money.new(:USD, "0.013")
      assert Fees.calc_pay_request(Money.new(:USD, "0.10")) |> Money.round(currency_digits: 3) == Money.new(:USD, "0.018")
      assert Fees.calc_pay_request(Money.new(:USD, "0.50")) |> Money.round(currency_digits: 3) == Money.new(:USD, "0.043")
      assert Fees.calc_pay_request(Money.new(:USD, "1.00")) |> Money.round(currency_digits: 3) == Money.new(:USD, "0.068")
      assert Fees.calc_pay_request(Money.new(:USD, "5.00")) |> Money.round(currency_digits: 3) == Money.new(:USD, "0.193")
      assert Fees.calc_pay_request(Money.new(:USD, "10.00")) |> Money.round(currency_digits: 3) == Money.new(:USD, "0.318")
      assert Fees.calc_pay_request(Money.new(:USD, "50.00")) |> Money.round(currency_digits: 3) == Money.new(:USD, "0.868")
      assert Fees.calc_pay_request(Money.new(:USD, "100")) |> Money.round(currency_digits: 3) == Money.new(:USD, "1.368")
      assert Fees.calc_pay_request(Money.new(:USD, "500")) |> Money.round(currency_digits: 3) == Money.new(:USD, "5.368")
      assert Fees.calc_pay_request(Money.new(:USD, "5000")) |> Money.round(currency_digits: 3) == Money.new(:USD, "10.000")
    end
  end
end
