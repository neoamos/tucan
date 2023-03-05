defmodule App.Repo.Migrations.EventTagIndex do
  use Ecto.Migration

  def change do
    create index(:event_tag, [:event_storage_id])
    create index(:event_relay, [:event_storage_id])
    create index(:event_relay, [:relay_id])
    create index(:user, [:contact_list_id])
  end
end
