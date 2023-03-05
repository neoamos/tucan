defmodule App.Storage.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  alias App.Storage.EventStorage

  schema "event_tag" do
    belongs_to :event_storage, EventStorage
    field :position, :integer
    field :tag, :string
    field :column1, :string
    field :column2, :string
    field :column3, :string
    field :column4, :string
    field :column5, :string
    field :rest, :string


    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:event_id, :position, :tag,
      :column1, :column2, :column3, :column4, :column5, :rest])
    |> validate_required([:event_id, :tag, :position])
    |> validate_number(:position, greater_than_or_equal_to: 0)
  end


end