defmodule App.Repo.Migrations.Profile do
  use Ecto.Migration

  def change do
    alter table(:user) do
      add :website, :text
      add :username, :text
    end

    create index(:user, [:website])
    create index(:user, [:username])
  end
end
