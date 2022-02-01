defmodule NanopayWeb.API.Spec do
  alias OpenApiSpex.{Info, OpenApi, Paths, Server}

  @behaviour OpenApi

  @impl OpenApi
  def spec do
    api = %OpenApi{
      # Populate the Server info from a phoenix endpoint
      servers: [
        Server.from_endpoint(NanopayWeb.Endpoint)
      ],

      info: %Info{
        title: "Nanopay API",
        version: "1.0"
      },

      # Populate the paths from a phoenix router
      paths: Paths.from_router(NanopayWeb.Router)
    }

    # Discover request/response schemas from path specs
    OpenApiSpex.resolve_schema_modules(api)
  end
end
