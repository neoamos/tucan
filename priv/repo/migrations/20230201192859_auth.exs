defmodule App.Repo.Migrations.Auth do
  use Ecto.Migration

  def change do
    create table(:rememberable) do
      add :series_hash, :text, null: false
      add :token_hash, :text, null: false
      add :token_created_at, :utc_datetime, null: false
      add :user_id, references(:user, on_delete: :delete_all), null: false

      timestamps()
    end

    create table(:session) do
      add :uuid, :text, null: false
      add :user_id, references(:user, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:session, [:user_id])
    create index(:session, [:uuid])
    create index(:rememberable, [:user_id])
    create index(:rememberable, [:series_hash])
    create index(:rememberable, [:token_hash])
    create unique_index(:rememberable, [:user_id, :series_hash, :token_hash])
  end
end
