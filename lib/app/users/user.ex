defmodule App.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias App.Storage.EventStorage
  alias App.User.UserRelay
  alias App.User.Follower

  schema "user" do
    field :pubkey, :binary
    field :name, :string
    field :username, :string
    field :picture, :string
    field :about, :string
    field :website, :string

    field :lud06, :string
    field :lud16, :string
    field :banner, :string

    belongs_to :metadata, EventStorage
    belongs_to :contact_list, EventStorage

    field :nip5_identifier, :string
    field :nip5_verified, :boolean
    field :nip5_checked_at, :utc_datetime

    field :follower_count, :integer
    field :following_count, :integer

    has_many :relays, UserRelay, preload_order: [desc: :updated_at]

    has_many :followers, Follower, foreign_key: :followed_id, on_replace: :delete
    has_many :following, Follower, foreign_key: :follower_id, on_replace: :delete

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:pubkey, :name, :username, :picture, :about, :website, :metadata_id, :contact_list_id, :nip5_identifier, :nip5_verified,
      :nip5_checked_at, :follower_count, :following_count, :lud06, :lud16, :banner])
    |> validate_required([:pubkey])
    |> foreign_key_constraint(:metadata_id)
    |> foreign_key_constraint(:contact_list_id)
    |> validate_length(:pubkey, is: 32, count: :bytes)
    |> validate_length(:name, max: 100)
    |> validate_length(:picture, max: 2048)
    |> validate_length(:about, max: 10000)
    |> validate_length(:nip5_identifier, max: 100)
  end

end
