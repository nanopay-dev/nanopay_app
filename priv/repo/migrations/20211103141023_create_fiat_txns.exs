defmodule Nanopay.Repo.Migrations.CreateFiatTxns do
  use Ecto.Migration

  def change do
    create table(:fiat_txns) do
      add :description, :string
      add :base_amount, :money_with_currency
      add :user_amount, :money_with_currency
      add :balance, :money_with_currency
      add :user_id, references(:users, type: :binary_id)
      add :subject_type, :string
      add :subject_id, :binary_id

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:fiat_txns, [:user_id])
    create index(:fiat_txns, [:subject_type, :subject_id])
  end
end
