defmodule App.Repo.Migrations.App do
  use Ecto.Migration

  def change do

    create table(:user) do
      add :pubkey, :bytea, null: false
      add :name, :text
      add :picture, :text
      add :about, :text
      add :metadata_id, references(:event_storage, on_delete: :nilify_all)
      add :contact_list_id, references(:event_storage, on_delete: :nilify_all)

      add :lud06, :text
      add :lud16, :text
      add :banner, :text

      add :nip5_identifier, :text
      add :nip5_verified, :boolean
      add :nip5_checked_at, :utc_datetime

      add :follower_count, :integer, default: 0
      add :following_count, :integer, default: 0

      timestamps()
    end

    create unique_index(:user, [:pubkey])
    create index(:user, [:name])
    create index(:user, [:nip5_identifier])
    create index(:user, [:nip5_verified])
    create index(:user, [:nip5_checked_at])
    create index(:user, [:metadata_id])
    create index(:user, [:inserted_at])
    create index(:user, [:updated_at])
    create index(:user, [:follower_count])
    create index(:user, [:following_count])

    create table(:post) do
      add :user_id, references(:user, on_delete: :nilify_all)
      add :event_storage_id, references(:event_storage, on_delete: :delete_all)
      add :event_id, :bytea, null: false
      add :sensitive, :text
      add :content, :text
      add :created_at, :utc_datetime

      add :like_count, :integer, default: 0
      add :reply_count, :integer, default: 0
      add :view_count, :integer, default: 0

      add :reply_id, references(:post, on_delete: :nilify_all)
      add :root_reply_id, references(:post, on_delete: :nilify_all)
      add :repost_id, references(:post, on_delete: :nilify_all)

      timestamps()
    end

    create index(:post, [:user_id])
    create unique_index(:post, [:event_storage_id])
    create unique_index(:post, [:event_id])
    create index(:post, [:sensitive])
    create index(:post, [:like_count])
    create index(:post, [:reply_count])
    create index(:post, [:view_count])
    create index(:post, [:reply_id])
    create index(:post, [:root_reply_id])
    create index(:post, [:repost_id])
    create index(:post, [:inserted_at])
    create index(:post, [:updated_at])
    create index(:post, [:created_at])

    create table(:post_mention) do
      add :mentioned_id, references(:post, on_delete: :delete_all), null: false
      add :mentioned_by_id, references(:post, on_delete: :delete_all), null: false
      add :position, :integer, null: false # index of mention in tags
      add :type, :text # root or reply
    end

    create index(:post_mention, [:mentioned_id])
    create index(:post_mention, [:mentioned_by_id])
    create index(:post_mention, [:position])
    create index(:post_mention, [:type])

    create table(:user_mention) do
      add :mentioned_id, references(:user, on_delete: :delete_all), null: false
      add :mentioned_by_id, references(:post, on_delete: :delete_all), null: false
      add :position, :integer, null: false
    end

    create index(:user_mention, [:mentioned_id])
    create index(:user_mention, [:mentioned_by_id])
    create index(:user_mention, [:position])

    create table(:like) do
      add :user_id, references(:user, on_delete: :delete_all), null: false
      add :post_id, references(:post, on_delete: :delete_all), null: false
      add :event_storage_id, references(:user, on_delete: :nilify_all), null: false

      add :positive, :boolean, null: false
      add :created_at, :utc_datetime, null: false

      timestamps()
    end

    create index(:like, [:user_id])
    create index(:like, [:post_id])
    create index(:like, [:event_storage_id])
    create index(:like, [:positive])
    create index(:like, [:created_at])
    create index(:like, [:inserted_at])
    create unique_index(:like, [:user_id, :post_id])

    create table(:hashtag) do
      add :post_id, references(:post, on_delete: :delete_all), null: false
      add :tag, :text, null: false
    end

    create index(:hashtag, [:post_id])
    create index(:hashtag, [:tag])

    create table(:post_relay) do
      add :post_id, references(:post, on_delete: :delete_all), null: false
      add :relay_id, references(:relay, on_delete: :delete_all), null: false

      add :recommended, :boolean

      timestamps()
    end

    create index(:post_relay, [:post_id])
    create index(:post_relay, [:relay_id])
    create unique_index(:post_relay, [:post_id, :relay_id])

    create table(:user_relay) do
      add :user_id, references(:user, on_delete: :delete_all), null: false
      add :relay_id, references(:relay, on_delete: :delete_all), null: false
      add :position, :integer
      add :read, :boolean
      add :write, :boolean

      add :recommended, :boolean

      timestamps()
    end

    create index(:user_relay, [:user_id])
    create index(:user_relay, [:relay_id])
    create unique_index(:user_relay, [:user_id, :relay_id])

    create table(:follower) do
      add :follower_id, references(:user, on_delete: :delete_all), null: false
      add :followed_id, references(:user, on_delete: :delete_all), null: false
      add :petname, :text
      add :position, :integer

      timestamps()
    end

    create index(:follower, [:follower_id])
    create index(:follower, [:followed_id])
    create unique_index(:follower, [:follower_id, :followed_id])
  end
end
