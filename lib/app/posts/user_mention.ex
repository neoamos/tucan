defmodule App.Post.UserMention do
  use Ecto.Schema
  import Ecto.Changeset

  alias App.Post
  alias App.Relay
  alias App.User

  schema "user_mention" do
    belongs_to :mentioned, User
    belongs_to :mentioned_by, Post
    field :position, :integer
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:mentioned_id, :mentioned_by_id, :position])
    |> foreign_key_constraint(:mentioned_by_id)
    |> foreign_key_constraint(:mentioned_id)
  end

end
