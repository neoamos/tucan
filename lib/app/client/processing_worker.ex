defmodule App.Client.ProcessingWorker do
  import Ecto.Query, warn: false
  alias App.Repo

  alias App.Storage
  alias App.Storage.EventStorage
  alias App.Relay
  alias App.Client.WebSocketClient
  alias NostrTools.Filter
  alias App.Users
  alias App.User

  def process_events opts \\ %{} do
    limit = (opts[:limit] || 5000)
    kinds = (opts[:kinds] || [0,1,3,7])
    query = from es in EventStorage,
      order_by: es.inserted_at,
      preload: [:tags],
      where: es.kind in ^kinds,
      limit: ^limit

    query = if opts[:status] do
      from es in query,
        where: es.processing_status == ^opts[:status]
    else
      from es in query,
        where: is_nil(es.processing_status)
    end

    query = if opts[:id] do
      from es in query,
        where: fragment("MOD(?,?)=?", es.id, ^opts[:worker_count], ^opts[:id])
    else
      query
    end

    events = Repo.all(query)
    # stream = Task.async_stream(events, fn es ->
    #   try do
    #     process_event(es)
    #   rescue
    #     e -> Storage.set_processed(es, "error")
    #   end
    # end, max_concurrency: (opts[:concurrency] || 5), timeout: :infinity)
    # Enum.map(stream, fn i -> i end)

    Enum.map(events, fn es ->
      try do
        process_event(es)
      rescue
        _ -> Storage.set_processed(es, "error")
      end
    end)
  end

  def process_event_id event_storage_id do
    es = Repo.one(from es in EventStorage,
      where: es.id==^event_storage_id,
      preload: [:tags])
    if es do
      process_event(es)
    end
  end

  def process_event es do
    event = Storage.event_from_storage(es)
    case event.kind do
      0 ->
        {latest_event, _} = Storage.get_latest_event(0, event.pubkey)
        if latest_event.id == event.id do
          App.Users.parse_metadata(es, event)
        else
          Storage.set_processed(es, "outdated")
        end
        # Storage.set_old_status("outdated", 0, latest_event.pubkey, latest_event.created_at)
      3 ->
        {latest_event, _} = Storage.get_latest_event(3, event.pubkey)
        if latest_event.id == event.id do
          App.Users.parse_contact_list(es, event)
        else
          Storage.set_processed(es, "outdated")
        end
        # Storage.set_old_status("outdated", 3, latest_event.pubkey, latest_event.created_at)
      1 -> App.Posts.parse_post(es, event)
      7 -> App.Posts.parse_reaction(es, event)
      _ -> nil
    end
  end

  def verify_nip5 limit \\ 5000 do
    one_hour_ago = Timex.shift(Timex.now(), hours: -1)
    query = from u in User,
      where: not is_nil(u.nip5_identifier),
      where: u.nip5_checked_at < ^one_hour_ago or is_nil(u.nip5_checked_at),
      limit: ^limit
    users = Repo.all(query)
    stream = Task.async_stream(users, fn user ->
      try do
        Users.verify_nip5(user)
      rescue
        e ->
          IO.inspect(e)
          now = DateTime.utc_now()
          user
          |> User.changeset(%{nip5_verified: false, nip5_checked_at: now})
          |> Repo.update()
      end
    end, timeout: :infinity)
    Enum.map(stream, fn i -> i end)
  end

  def delete_old_events kind, limit \\ 1000 do
    if kind == 3 or kind == 0 do
      query = from es in EventStorage,
        where: es.kind==^kind,
        group_by: [es.pubkey],
        having: count("*") > 3,
        limit: ^limit,
        select: es.pubkey
      pubkeys = Repo.all(query)
      Enum.map(pubkeys, fn pubkey ->
        {latest_event, _} = Storage.get_latest_event(kind, pubkey)
        Storage.delete_old_events(kind, latest_event.pubkey, latest_event.created_at)
      end)
    end
  end

  def connect_relays do
    query = from r in Relay, where: r.read==true
    relays = Repo.all(query)
    urls = Repo.all(query)
    |> Enum.map(fn relay ->
      Users.normalize_relay(relay.url)
    end)
    |> Enum.uniq()
    |> Enum.filter(fn url -> String.match?(url, ~r(^wss://.+)) end)
    Enum.map(urls, fn url ->
      if !WebSocketClient.connected?(url) do
        WebSocketClient.connect(url)
        |> case do
          {:ok, _} -> IO.puts("Connected to #{url}")
          other -> IO.puts("failed to connect to #{url}: #{inspect other}")
        end
      end
    end)
  end

  def request opts \\ %{} do
    query = from r in Relay, where: r.read==true
    relays = Repo.all(query)
    urls = relays
    |> Enum.map(fn relay ->
      Users.normalize_relay(relay.url)
    end)
    kinds = opts[:kinds] || [0,1]
    filter = opts[:filter] || %Filter{kinds: kinds}
    Enum.map(urls, fn url ->
      if WebSocketClient.connected?(url) do
        WebSocketClient.request_async(url, random_string(10), filter)
      end
    end)
  end

  def connected_relays do
    query = from r in Relay, where: r.read==true
    relays = Repo.all(query)
    urls = relays
    |> Enum.map(fn relay ->
      Users.normalize_relay(relay.url)
    end)
    |> Enum.filter(fn url -> String.match?(url, ~r(^wss://.+)) end)
    Map.new(urls, fn url ->
      {url, WebSocketClient.connected?(url)}
    end)
  end

  def connected_relay_count do
    App.Client.ProcessingWorker.connected_relays
    |> Map.values()
    |> Enum.filter(fn v -> v end)
    |> length()
  end

  def random_string(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, length)
  end

  def store_archived_events path, start \\ 0 do
    stream = File.stream!(path)
    stream
    |> Stream.with_index()
    |> Enum.map(fn {line, i} ->
      if i >= start do
        case Jason.decode(line) do
          {:ok, json} ->
            case NostrTools.Event.create(json) do
              {:ok, event} ->
                if (event.kind in [0,1,3,5,7]) and NostrTools.Event.valid?(event) do
                  try do
                    Storage.store(event)
                    |> case do
                      {:ok, _} -> IO.puts("#{i} Stored")
                      other -> IO.puts("#{i} failed to store #{inspect other}")
                    end
                  rescue
                    e -> IO.puts("#{i} error #{inspect e}")
                  end

                end
              _ -> IO.puts("#{i}: invalid event at")
            end
          _ ->
            IO.puts("#{i}: failed to parse line #{i}: #{inspect(line)}")
        end
      end
    end)
  end

end
