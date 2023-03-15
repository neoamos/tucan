defmodule App.Storage do
  import Ecto.Query, warn: false
  alias App.Repo

  alias NostrTools.Event
  alias NostrTools.Filter
  alias App.Storage.EventStorage
  alias App.Storage.Tag
  alias App.Storage.EventRelay
  alias App.Relay
  alias App.Relays

  def store(%Event{} = event, opts \\ %{}) do
    if NostrTools.Event.valid?(event) do
      event_storage = get_event({:event_id, event.id}, [:tags, :relays])
      if event_storage do
        if opts[:relays] do
          relays = create_event_relays(opts[:relays]) ++ event_storage.relays
          relays = Enum.uniq_by(relays, fn r -> r.relay_id end)

          event_storage
          |> EventStorage.changeset(%{})
          |> Ecto.Changeset.put_assoc(:relays, relays)
          |> Repo.update()
        else
          {:ok, event_storage}
        end
      else
        tags = create_tags(event.tags)
        event_relays = create_event_relays(opts[:relays])
        attrs = %{
          event_id: event.id,
          pubkey: event.pubkey,
          created_at: event.created_at,
          kind: event.kind,
          sig: event.sig,
          content: event.content,
          received_from_client: (opts[:received_from_client] || false)
        }

        %EventStorage{}
        |> EventStorage.changeset(attrs)
        |> Ecto.Changeset.put_assoc(:tags, tags)
        |> Ecto.Changeset.put_assoc(:relays, event_relays)
        |> Repo.insert()
      end
    else
      {:error, "Invalid event"}
    end
  end

  def create_tags tags do
    tags
    |> Enum.with_index()
    |> Enum.map(fn {[t | values], index} ->
      %Tag{
        position: index,
        tag: t,
        column1: Enum.at(values, 0, nil),
        column2: Enum.at(values, 1, nil),
        column3: Enum.at(values, 2, nil),
        column4: Enum.at(values, 3, nil),
        column5: Enum.at(values, 4, nil),
        rest: Jason.encode!(Enum.slice(values, 5..-1))
      }
    end)
  end

  def create_event_relays(relays) when is_list(relays) do
    Enum.map(relays, fn url ->
      relay = Relays.get_or_create(url)
      %EventRelay{
        relay_id: relay.id
      }
    end)
  end
  def create_event_relays(relays) when is_nil(relays), do: []

  def delete(%Event{} = deletion_event, opts \\ %{}) do

  end

  def get_events(%Filter{} = filter, opts \\ %{}) do

  end

  def get_event id, preload \\ []
  def get_event({:storage_id, id}, preload) do
    query = from e in EventStorage,
      where: e.id==^id,
      preload: ^([:tags] ++ preload)

    Repo.one(query)
  end

  def get_event({:event_id, event_id}, preload) do
    query = from e in EventStorage,
      where: e.event_id==^event_id,
      preload: ^([:tags] ++ preload)

    Repo.one(query)
  end

  def get_latest_event kind, pubkey do
    query = from e in EventStorage,
      where: e.kind==^kind and e.pubkey==^pubkey,
      order_by: [desc: e.created_at],
      limit: 1,
      preload: [:tags]
    es = Repo.one(query, timeout: :infinity)
    if es do
      e = event_from_storage(es)
      {e, es}
    else
      {nil, nil}
    end
  end

  def delete_old_events kind, pubkey, before do
    query = from es in EventStorage,
      where: es.kind==^kind and es.created_at < ^before and es.pubkey==^pubkey

    Repo.delete_all(query)
  end

  def set_old_status status, kind, pubkey, before do
    query = from es in EventStorage,
      where: es.kind==^kind and es.created_at < ^before and es.pubkey==^pubkey,
      where: es.processing_status != ^status,
      update: [set: [processing_status: ^status]]

    Repo.update_all(query, [])
  end

  def set_deleted_prior_events(es, val) do
    query = from e in EventStorage, where: e.id==^es.id,
      update: [set: [deleted_prior_events: ^val]]
    Repo.update_all(query, [])
  end

  def event_from_storage(%EventStorage{} = es) do
    %Event{
      id: es.event_id,
      pubkey: es.pubkey,
      created_at: es.created_at,
      kind: es.kind,
      tags: parse_tags(es.tags),
      sig: es.sig,
      content: es.content || ""
    }
  end

  def parse_tags(tags) do
    tags
    |> Enum.sort_by(fn t -> t.position end)
    |> Enum.map(fn t ->
      tag = [
        t.tag,
        t.column1,
        t.column2,
        t.column3,
        t.column4,
        t.column5,
      ]
      |> Enum.filter(fn t -> t != nil end)

      tag ++ Jason.decode!(t.rest)
    end)
  end

  def delete_replaced_events do

  end

  def set_processed es, status \\ nil do
    time = DateTime.utc_now() |> DateTime.truncate(:second)
    es
    |> Ecto.Changeset.change(processed_at: time, processing_status: status)
    |> Repo.update()
  end

end
