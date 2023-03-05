defmodule App.Repo.Migrations.Init do
  use Ecto.Migration

  def change do

    create table(:relay) do
      add :url, :text, null: false

      add :received_start, :utc_datetime
      add :received_end, :utc_datetime
      add :last_connected, :utc_datetime

      timestamps()
    end

    create table(:event_storage) do
      add :event_id, :bytea, null: false
      add :pubkey, :bytea
      add :created_at, :utc_datetime
      add :kind, :integer
      add :sig, :bytea
      add :content, :text

      add :received_from_client, :boolean, default: false
      add :deleted, :boolean, default: false
      add :processed_at, :utc_datetime
      add :processing_status, :text

      timestamps()
    end

    alter table(:event_storage) do
      add :deleted_by_id, references(:event_storage, on_delete: :nilify_all)
    end

    create table(:event_tag) do
      add :event_storage_id, references(:event_storage, on_delete: :delete_all), null: false
      add :position, :integer, null: false
      add :tag, :text, null: false
      add :column1, :text
      add :column2, :text
      add :column3, :text
      add :column4, :text
      add :column5, :text
      add :rest, :text

      timestamps()
    end

    create table(:event_relay) do
      add :event_storage_id, references(:event_storage, on_delete: :delete_all), null: false
      add :relay_id, references(:relay, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:relay, [:url])
    create index(:relay, [:received_start])
    create index(:relay, [:received_end])
    create index(:relay, [:last_connected])

    create unique_index(:event_relay, [:event_storage_id, :relay_id])

    create unique_index(:event_storage, [:event_id])
    create index(:event_storage, [:pubkey])
    create index(:event_storage, [:created_at])
    create index(:event_storage, [:kind])
    create index(:event_storage, [:received_from_client])
    create index(:event_storage, [:deleted])
    create index(:event_storage, [:deleted_by_id])

    create index(:event_tag, [:tag])
    create index(:event_tag, [:tag, :column1])
    create index(:event_tag, [:column1])
    create index(:event_tag, [:column2])
    create index(:event_tag, [:column3])
    create index(:event_tag, [:column4])
    create index(:event_tag, [:column5])
    create index(:event_storage, [:processed_at])
    create index(:event_storage, [:processing_status])
  end
end
