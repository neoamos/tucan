defmodule App.Repo.Migrations.UserRelays do
  use Ecto.Migration

  def change do
    alter table(:user_relay) do
      add :profile, :boolean
      add :global, :boolean
    end

    create index(:user_relay, [:profile])
    create index(:user_relay, [:global])
  end
end
