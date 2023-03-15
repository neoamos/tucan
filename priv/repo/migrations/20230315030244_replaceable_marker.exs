defmodule App.Repo.Migrations.ReplaceableMarker do
  use Ecto.Migration

  def change do
    alter table(:event_storage) do
      add :deleted_prior_events, :boolean
    end

    create index(:event_storage, [:deleted_prior_events])
  end
end
