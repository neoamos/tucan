defmodule App.Storage.EventRelay do
  use Ecto.Schema
  import Ecto.Changeset

  alias App.Storage.EventStorage
  alias App.Relay

  schema "event_relay" do
    belongs_to :event_storage, EventStorage
    belongs_to :relay, Relay

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [])
  end

end