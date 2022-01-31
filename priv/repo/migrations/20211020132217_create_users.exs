defmodule Nanopay.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string
      add :password_hash, :string
      add :key_data, :map
      add :verified_at, :utc_datetime
      add :stripe_id, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, ["LOWER(email)"], name: :users_email_index)
  end
end
