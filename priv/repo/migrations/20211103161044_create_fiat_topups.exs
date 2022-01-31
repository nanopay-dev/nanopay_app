defmodule Nanopay.Repo.Migrations.CreateFiatTopups do
  use Ecto.Migration

  def change do
    create table(:fiat_topups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string
      add :status, :integer
      add :amount, :money_with_currency
      add :fee, :money_with_currency
      add :user_id, references(:users, type: :binary_id)
      add :stripe_id, :string

      timestamps(type: :utc_datetime)
    end

    create index(:fiat_topups, [:status])
    create index(:fiat_topups, [:user_id])
  end
end
