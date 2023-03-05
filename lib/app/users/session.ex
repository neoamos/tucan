defmodule App.Users.Session do
  use Ecto.Schema
  import Ecto.Changeset

  alias App.User

  schema "session" do

    field :uuid, :string
    belongs_to :user, User

    timestamps()
  end

  def changeset(model, attrs) do
    model
    |> cast(attrs, [:uuid, :user_id])
    |> validate_required([:uuid, :user_id])
    |> foreign_key_constraint(:user_id)
  end

end
