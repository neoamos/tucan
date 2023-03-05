defmodule App.Relay do
  use Ecto.Schema
  import Ecto.Changeset

  schema "relay" do
    field :url, :string
    field :read, :boolean

    field :received_start, :utc_datetime
    field :received_end, :utc_datetime
    field :last_connected, :utc_datetime

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:url, :read])
    |> validate_required([:url])
    |> validate_length(:url, min: 1)
  end



end
