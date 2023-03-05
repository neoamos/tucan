defmodule App.Post.Hashtag do
  use Ecto.Schema
  import Ecto.Changeset

  alias App.User
  alias App.Post

  schema "hashtag" do
    belongs_to :post, Post
    field :tag, :string
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:post_id, :tag])
    |> validate_required([:post_id, :tag])
    |> validate_length(:tag, min: 1)
    |> foreign_key_constraint(:post_id)
  end

end
