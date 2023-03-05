defmodule App.Post.PostRelay do
  use Ecto.Schema
  import Ecto.Changeset

  alias App.Post
  alias App.Relay

  schema "post_relay" do
    belongs_to :post, Post
    belongs_to :relay, Relay
    field :recommended, :boolean

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:post_id, :relay_id, :recommended])
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:relay_id)
  end

end
