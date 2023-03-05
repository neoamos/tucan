defmodule App.Relays do
  import Ecto.Query, warn: false
  alias App.Repo

  alias App.Relay

  def get_or_create(url) do
    query = from r in App.Relay, where: r.url==^url
    relay = Repo.one(query)

    if relay do
      relay
    else
      %Relay{
        url: url
      }
      |> Relay.changeset()
      |> Repo.insert!()
    end
  end

  def set_read(relay_id, value) do
    q = from r in Relay,
      where: r.id==^relay_id,
      update: [set: [read: ^value]]
    Repo.update_all(q, [])
  end
end
