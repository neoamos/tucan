defmodule App.Post.PostMention do
  use Ecto.Schema
  import Ecto.Changeset

  alias App.Post
  alias App.Relay

  schema "post_mention" do
    belongs_to :mentioned, Post
    belongs_to :mentioned_by, Post
    field :position, :integer # index of mention in tags
    field :type, :string # root or reply
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:mentioned_by_id, :mentioned_id, :position, :type])
    |> foreign_key_constraint(:mentioned_by_id)
    |> foreign_key_constraint(:mentioned_id)
  end

end
