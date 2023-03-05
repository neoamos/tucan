defmodule App.Repo.Migrations.RelayRead do
  use Ecto.Migration

  def change do
    alter table(:relay) do
      add :read, :boolean
    end

    create index(:relay, [:read])
  end
end
