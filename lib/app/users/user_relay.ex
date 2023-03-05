defmodule App.User.UserRelay do
  use Ecto.Schema
  import Ecto.Changeset

  alias App.User
  alias App.Relay

  schema "user_relay" do
    belongs_to :user, User
    belongs_to :relay, Relay
    field :position, :integer
    field :read, :boolean
    field :write, :boolean
    field :profile, :boolean
    field :global, :boolean

    field :recommended, :boolean

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:user_id, :relay_id, :position, :read, :write, :profile, :global, :recommended])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:relay_id)
  end

end
