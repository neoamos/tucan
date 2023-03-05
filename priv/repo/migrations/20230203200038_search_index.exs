defmodule App.Repo.Migrations.SearchIndex do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION pg_trgm;"
    execute "CREATE INDEX user_nip5_trgm_index ON \"user\" USING gin (lower(nip5_identifier) gin_trgm_ops);"
    execute "CREATE INDEX user_name_trgm_index ON \"user\" USING gin (lower(name) gin_trgm_ops);"
  end
end
