defmodule App.Post do
  use Ecto.Schema
  import Ecto.Changeset

  alias App.Post
  alias App.User
  alias App.Storage.EventStorage
  alias App.Post.Hashtag
  alias App.Post.Reply
  alias App.Post.Like
  alias App.Post.PostMention
  alias App.Post.UserMention
  alias App.Relay
  alias App.Post.PostRelay
  alias App.Storage.EventRelay

  schema "post" do
    belongs_to :user, User
    belongs_to :event_storage, EventStorage
    field :event_id, :binary
    field :sensitive, :string
    field :content, :string
    field :created_at, :utc_datetime

    field :like_count, :integer
    field :reply_count, :integer
    field :view_count, :integer

    belongs_to :reply, Post
    belongs_to :root_reply, Post
    belongs_to :repost, Post

    has_many :likes, Like, on_replace: :delete
    has_many :hashtags, Hashtag, on_replace: :delete
    has_many :post_mentions, PostMention, foreign_key: :mentioned_by_id, on_replace: :delete
    has_many :post_mentions_by, PostMention, foreign_key: :mentioned_id, on_replace: :delete
    has_many :user_mentions, UserMention, foreign_key: :mentioned_by_id, on_replace: :delete
    has_many :user_mentions_by, UserMention, foreign_key: :mentioned_id, on_replace: :delete
    many_to_many :received_by, Relay, join_through: EventRelay, join_keys: [event_storage_id: :event_storage_id, relay_id: :id]

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:user_id, :event_storage_id, :event_id, :sensitive, :content, :created_at, :like_count, :reply_count,
      :view_count, :reply_id, :root_reply_id, :repost_id])
    |> validate_required([:event_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:event_storage_id)
    |> foreign_key_constraint(:reply_id)
    |> foreign_key_constraint(:root_reply_id)
    |> foreign_key_constraint(:repost_id)
    |> validate_length(:event_id, is: 32, count: :bytes)
    |> unique_constraint(:event_storage_id)
  end

end
