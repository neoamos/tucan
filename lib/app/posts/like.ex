defmodule App.Post.Like do
  use Ecto.Schema
  import Ecto.Changeset

  alias App.User
  alias App.Post
  alias App.Storage.EventStorage

  schema "like" do
    belongs_to :user, User
    belongs_to :post, Post
    belongs_to :event_storage, EventStorage

    field :positive, :boolean
    field :created_at, :utc_datetime

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:user_id, :post_id, :event_storage_id, :positive, :created_at])
    |> validate_required([:user_id, :post_id, :event_storage_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:event_storage_id)
  end

end
