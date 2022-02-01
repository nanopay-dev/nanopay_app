defmodule NanopayWeb.API.Schemas.PayRequest do
  alias OpenApiSpex.Schema

  defmodule Params do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "PayRequest params",
      description: "Payment request parameters",
      type: :object,
      properties: %{
        keypath: %Schema{type: :string, description: "Key derivation path"},
        satoshis: %Schema{type: :integer, description: "Required satoshis"},
        ctx: %Schema{
          type: :object,
          description: "Birth date",
          properties: %{
            version: %Schema{type: :integer, description: "Tx version", default: 1},
            prevouts: %Schema{type: :string, description: "TxIn outpoints", pattern: ~r/\A(([0-9a-f]{2}){36})+\z/i},
            sequences: %Schema{type: :string, description: "TxIn sequences", pattern: ~r/\A(([0-9a-f]{2}){4})+\z/i},
            outhash: %Schema{type: :string, description: "TxOuts hash", pattern: Nanopay.regex(:sha256hex)},
            locktime: %Schema{type: :integer, description: "Tx locktime", default: 0},
          },
          required: [:outhash]
        },
      },
      required: [:satoshis, :ctx],
      example: %{
        "satoshis" => 10_000,
        "ctx" => %{
          "outhash" => "fa5135922a40bfad366c0691fc1c37fd862afda18347ef94a47e82168690fd2b"
        }
      }
    })
  end

  defmodule Response do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "PayRequest response",
      description: "Payment request response",
      type: :object,
      properties: %{
        data: %Schema{
          type: :object,
          properties: %{
            id: %Schema{type: :string, description: "PayRequest UUID"},
            status: %Schema{type: :string, description: "PayRequest status"}
          }
        }
      },
      example: %{
        "satoshis" => 10_000,
        "ctx" => %{
          "outhash" => "fa5135922a40bfad366c0691fc1c37fd862afda18347ef94a47e82168690fd2b"
        }
      }
    })
  end
end
