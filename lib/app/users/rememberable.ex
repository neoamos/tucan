defmodule App.Users.Rememberable do
  use Ecto.Schema
  import Ecto.Changeset

  alias App.User

  schema "rememberable" do

    field :series_hash, :string
    field :token_hash, :string
    field :token_created_at, :utc_datetime
    belongs_to :user, User


    timestamps()
  end

  def changeset(model, attrs) do
    model
    |> cast(attrs, [:series_hash, :token_hash, :token_created_at, :user_id])
    |> validate_required([:series_hash, :token_hash, :token_created_at, :user_id])
    |> foreign_key_constraint(:user_id)
  end

end
