defmodule NanopayWeb.API.Schemas.Errors do
  alias OpenApiSpex.Schema

  defmodule BadRequest do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Bad request error",
      description: "The request failed one or more validations.",
      type: :object,
      properties: %{
        ok: %Schema{type: :boolean},
        error: %Schema{type: :string, description: "Error description"}
      }
    })
  end

end
