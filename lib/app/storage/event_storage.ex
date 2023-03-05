defmodule App.Storage.EventStorage do
  use Ecto.Schema
  import Ecto.Changeset

  alias App.Storage.EventRelay
  alias App.Storage.Tag

  schema "event_storage" do
    field :event_id, :binary
    field :pubkey, :binary
    field :created_at, :utc_datetime
    field :kind, :integer
    field :sig, :binary
    field :content, :string
    has_many :tags, App.Storage.Tag

    field :received_from_client, :boolean
    field :deleted, :boolean
    field :processed_at, :utc_datetime
    field :processing_status, :string
    belongs_to :deleted_by, __MODULE__
    has_many :relays, EventRelay, on_replace: :delete


    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:event_id, :pubkey, :created_at,
      :kind, :sig, :content, :deleted, :processed_at, :processing_status])
    |> validate_required([:event_id, :pubkey,
      :created_at, :kind, :sig])
    |> validate_length(:event_id, is: 32, count: :bytes)
    |> validate_length(:pubkey, is: 32, count: :bytes)
    |> validate_length(:sig, is: 64, count: :bytes)
    |> validate_number(:kind, greater_than_or_equal_to: 0)
    |> unique_constraint(:event_id)
  end


end
