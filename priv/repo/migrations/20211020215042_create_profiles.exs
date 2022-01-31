defmodule Nanopay.Repo.Migrations.CreateProfiles do
  use Ecto.Migration

  def change do
    create table(:profiles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :handle, :string
      add :pubkey, :string
      add :enc_privkey, :string
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:profiles, ["LOWER(handle)"], name: :profiles_handle_index)
    create unique_index(:profiles, ["LOWER(pubkey)"], name: :profiles_pubkey_index)
    create index(:profiles, [:user_id])
  end
end
