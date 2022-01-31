defmodule Nanopay.Repo do
  use Ecto.Repo,
    otp_app: :nanopay,
    adapter: Ecto.Adapters.Postgres
end
