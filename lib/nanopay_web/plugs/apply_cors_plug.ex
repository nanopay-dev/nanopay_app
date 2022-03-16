defmodule NanopayWeb.ApplyCORSPlug do
  @moduledoc """
  Plug that wraps around `CORSPlug` which is conditionally applied if the
  request path matches the given `:on` option.
  """

  @doc false
  def init(opts) do
    cors_opts = opts
    |> Keyword.get(:cors, [])
    |> CORSPlug.init()

    {opts, cors_opts}
  end

  @doc false
  def call(conn, {opts, cors_opts}) do
    with %Regex{} = regex <- Keyword.get(opts, :on),
         true <- Regex.match?(regex, conn.request_path)
    do
      CORSPlug.call(conn, cors_opts)
    else
      _ -> conn
    end
  end

end
