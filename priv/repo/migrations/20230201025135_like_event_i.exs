defmodule App.Repo.Migrations.LikeEventI do
  use Ecto.Migration

  def change do
    alter table(:like) do
      remove :event_storage_id
      add :event_storage_id, references(:event_storage, on_delete: :nilify_all), null: false
    end
  end
end
