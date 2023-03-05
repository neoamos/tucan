defmodule App.Repo.Migrations.LikeIndex do
  use Ecto.Migration

  def change do
    create index(:like, [:event_storage_id])
  end
end
