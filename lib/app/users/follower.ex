defmodule App.User.Follower do
  use Ecto.Schema
  import Ecto.Changeset

  alias App.User
  alias App.Storage.EventStorage

  schema "follower" do
    belongs_to :follower, User
    belongs_to :followed, User
    field :petname, :string
    field :position, :integer

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:follower_id, :followed_id, :petname, :position])
    |> validate_required([:follower_id, :followed_id])
    |> unique_constraint([:follower_id, :followed_id])
  end

end
