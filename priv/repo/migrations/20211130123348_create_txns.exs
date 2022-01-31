defmodule Nanopay.Repo.Migrations.CreateTxns do
  use Ecto.Migration

  def change do
    create table(:txns, primary_key: false) do
      add :txid, :string, primary_key: true
      add :rawtx, :binary
      add :status, :integer
      add :block, :integer
      add :mapi_status, :map
      add :mapi_count, :integer
      add :prev_mapi_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:txns, [:status, :block])
    create index(:txns, [:mapi_count, :prev_mapi_at])
  end
end
