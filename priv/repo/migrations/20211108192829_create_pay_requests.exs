defmodule Nanopay.Repo.Migrations.CreatePayRequests do
  use Ecto.Migration

  def change do
    create table(:pay_requests, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :status, :integer
      add :keypath, :string
      add :description, :string
      add :amount, :money_with_currency
      add :fee, :money_with_currency
      add :base_rate, :money_with_currency
      add :ctx, :map

      timestamps(type: :utc_datetime)
    end

    create index(:pay_requests, [:status])
    create index(:pay_requests, ["(encode(substring(sha256(id::text::bytea) FROM 1 FOR 4), 'hex'))"], name: :pay_requests_ref_index)
    create index(:pay_requests, [:inserted_at])
  end
end
