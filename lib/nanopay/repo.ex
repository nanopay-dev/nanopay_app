defmodule Nanopay.Repo do
  use Ecto.Repo,
    otp_app: :nanopay,
    adapter: Ecto.Adapters.Postgres

  use Scrivener,
    page_size: 10
end
