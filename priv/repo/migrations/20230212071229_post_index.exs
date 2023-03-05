defmodule App.Repo.Migrations.PostIndex do
  use Ecto.Migration

  def change do
    create index(:post, [:user_id, :event_storage_id, :reply_id, :created_at])
  end
end
