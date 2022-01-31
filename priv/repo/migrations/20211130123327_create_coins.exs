defmodule Nanopay.Repo.Migrations.CreateCoins do
  use Ecto.Migration

  def change do
    create table(:coins, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :channel, :integer
      add :path, :string
      add :satoshis, :integer
      add :script, :string
      add :funding_txid, :string
      add :funding_vout, :integer
      add :spending_txid, :string
      add :spending_vout, :integer
      add :locked_at, :utc_datetime
      add :pay_request_id, references(:pay_requests, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:coins, [:channel])
    create unique_index(:coins, [:funding_txid, :funding_vout])
    create unique_index(:coins, [:spending_txid, :spending_vout])
    create index(:coins, [:locked_at])
    create index(:coins, [:pay_request_id])
  end
end
