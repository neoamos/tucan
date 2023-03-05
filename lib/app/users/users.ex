defmodule App.Users do
  import Ecto.Query, warn: false
  alias App.Repo

  alias App.User
  alias App.User.UserRelay
  alias App.User.Follower

  alias App.Relay
  alias App.Relays

  alias App.Storage
  alias App.Storage.EventStorage

  alias App.Users.Session
  alias App.Users.Rememberable

  alias NostrTools.Crypto

  def parse_metadata event_storage, event do
    case Jason.decode(event.content) do
      {:ok, metadata} ->
        user = get_or_create(event.pubkey)
        attrs = %{
          name: trim(metadata["name"], 100),
          username: trim(metadata["username"], 100),
          picture: trim(metadata["picture"], 2048),
          about: trim(metadata["about"], 10000),
          metadata_id: event_storage.id,
          lud06: trim(metadata["lud06"], 2048),
          lud16: trim(metadata["lud16"], 100),
          banner: trim(metadata["banner"], 2048),
          website: trim(metadata["website"], 500),
        }

        attrs = case metadata["picture"] do
          "data" <> _ -> Map.put(attrs, :picture, nil)
          "http" <> _ ->
            Map.put(attrs, :picture, trim(metadata["picture"], 2048))
          _ -> attrs
        end

        attrs = if metadata["nip05"] != user.nip5_identifier do
          attrs
          |> Map.put(:nip5_identifier, trim(metadata["nip05"], 100))
          |> Map.put(:nip5_verified, nil)
          |> Map.put(:nip5_checked_at, nil)
        else
          attrs
        end
        user
        |> User.changeset(attrs)
        |> Repo.update()
        |> case do
          {:ok, _} ->
            Storage.set_processed(event_storage, "ok")
          other ->
            Storage.set_processed(event_storage, "error")
            other
        end
      other ->
        Storage.set_processed(event_storage, "error")
        IO.puts("Error parsing metadata: #{event.content}")
        other
    end

  end

  def parse_metadatas limit do
    query = from es in EventStorage,
      where: es.kind==0, # and is_nil(es.processed_at),
      order_by: es.inserted_at,
      limit: ^limit,
      preload: [:tags]
    event_storages = Repo.all(query)

    Enum.map(event_storages, fn es ->
      e = Storage.event_from_storage(es)
      parse_metadata(es, e)
    end)
  end

  def parse_contact_list event_storage, event do
    get_or_create(event.pubkey)
    user = get_user({:pubkey, event.pubkey}, [:following])
    following_map = Map.new(user.following, fn f ->
      {{f.follower_id, f.followed_id}, f}
    end)

    tags = Enum.filter(event.tags, fn t ->
      length(t) >= 2 and Enum.at(t, 0) == "p"
    end)

    following_users = tags
    |> Enum.with_index()
    |> Enum.uniq_by(fn {[_, pubkey | rest], i} = t -> pubkey end)
    |> Enum.flat_map(fn {[_, pubkey | rest], i} ->
      if Crypto.valid_hex?(pubkey, 32) do
        pubkey = Base.decode16!(pubkey, case: :lower)
        followed_user = get_or_create(pubkey)
        if Enum.at(rest, 0) != nil and Enum.at(rest, 0) != "" do
          add_relay(followed_user, Enum.at(rest, 0), recommended: true, set_server_read: true)
        end
        follower = following_map[{user.id, followed_user.id}]
        if follower do
          [Ecto.Changeset.change(follower, position: i)]
        else
          [%Follower{
            follower_id: user.id,
            followed_id: followed_user.id,
            petname: Enum.at(rest, 1),
            position: i
          }]
        end
      else
        []
      end
    end)

    # IO.inspect(following_users)

    user
    |> User.changeset(%{
      contact_list_id: event_storage.id
    })
    |> Ecto.Changeset.put_assoc(:following, following_users)
    |> Repo.update()
    |> case do
      {:ok, user} ->
        Storage.set_processed(event_storage, "ok")

        parse_user_relays(event_storage)
        user = Repo.preload(user, [:following])

        recalculate_follower_counts(user.id)

        new_follower_set = MapSet.new(user.following, fn f ->
          {f.follower_id, f.followed_id}
        end)
        old_follower_set = MapSet.new(Map.keys(following_map))
        change = MapSet.union(old_follower_set, new_follower_set)
        |> MapSet.difference(MapSet.intersection(old_follower_set, new_follower_set))

        Enum.map(change, fn {_, id} ->
          recalculate_follower_counts(id)
        end)

      other ->
        Storage.set_processed(event_storage, "error")
        IO.inspect(other)
    end
  end

  def parse_contact_lists limit do
    query = from es in EventStorage,
      where: es.kind==3, # and is_nil(es.processed_at),
      order_by: es.inserted_at,
      limit: ^limit,
      preload: [:tags]
    event_storages = Repo.all(query)
    IO.puts(length(event_storages))

    Enum.map(event_storages, fn es ->
      e = Storage.event_from_storage(es)
      parse_contact_list(es, e)
    end)
  end

  def parse_user_relays event do
    user = get_or_create(event.pubkey)
    q = from ur in UserRelay,
      where: ur.user_id==^user.id,
      update: [set: [read: nil, write: nil]]
    Repo.update_all(q, [])
    if is_binary(event.content) do
      case Jason.decode(event.content) do
        {:ok, relays} ->
          if is_map(relays) do
            Map.to_list(relays)
            |> Enum.map(fn {url, settings} ->
              url = normalize_relay(url)
              if String.match?(url, ~r(^wss://.+)) and is_map(settings) do
                opts = %{profile: true}
                opts = if is_boolean(settings["read"]), do: Map.put(opts, :read, settings["read"]), else: opts
                opts = if is_boolean(settings["write"]), do: Map.put(opts, :write, settings["write"]), else: opts
                add_relay(user, url, opts)
              end
            end)
          end
        other ->
          IO.inspect(other)
          other
      end
    end
  end

  def parse_user_relays_bulk limit, start \\ 0 do
    query = from u in User,
      where: not is_nil(u.contact_list_id),
      where: u.id > ^start,
      limit: ^limit,
      order_by: u.id,
      preload: [:contact_list]
    users = Repo.all(query)
    Enum.map(users, fn user ->
      IO.puts("Parsing #{user.id}")
      parse_user_relays(user.contact_list)
    end)
  end

  def verify_nip5 user do
    regex = ~r/[a-zA-Z0-9\-_\.]+/
    verified = if user.nip5_identifier && String.match?(user.nip5_identifier, regex) do
      case String.split(user.nip5_identifier, "@") do
        [name, domain] ->
          domain = String.replace(domain, ~s/\s/, "")
          url = "https://#{domain}/.well-known/nostr.json?name=#{name}"
          with true <- String.match?(domain, ~r/^[a-zA-Z0-9\-\.]+$/),
               {:ok, %{status_code: 200, body: json}} <- HTTPoison.get(url),
               {:ok, res} <- Jason.decode(json)
          do
            is_map(res) and is_map(res["names"]) and res["names"][name] == Base.encode16(user.pubkey, case: :lower)
          else
            other ->
              # IO.inspect(other)
              false
          end

        _ ->
          IO.puts("Invalid nip5: #{user.nip5_identifier}")
          false
      end
    else
      false
    end
    now = DateTime.utc_now()
    user
    |> User.changeset(%{nip5_verified: verified, nip5_checked_at: now})
    |> Repo.update()
  end

  def get_users limit, offset, filters, order, preload \\ [] do
    query = from u in User

    query = if filters[:following] do
      from u in query,
        join: f in Follower, on: f.followed_id==u.id,
        where: f.follower_id==^filters[:following].id
    else
      query
    end

    query = if filters[:followed] do
      from u in query,
        join: f in Follower, on: f.follower_id==u.id,
        where: f.followed_id==^filters[:followed].id
    else
      query
    end

    count_query = from u in query, select: count("*")

    query = if filters[:search] do
      term = "%#{String.downcase(filters[:search])}%"
      search = filters[:search]
      from u in query,
        where: (fragment("lower(?) like ?", u.nip5_identifier, ^term) and u.nip5_verified==true) or
        fragment("lower(?) like ?", u.name, ^term),
        order_by: fragment("similarity(coalesce(lower(?), ''),?) desc", u.nip5_identifier, ^search)
    else
      query
    end



    query = cond do
      !!filters[:following] ->
        from [u,f] in query,
          order_by: [asc: f.position]
      !!filters[:followed] ->
        from [u,f] in query,
          order_by: [asc: f.inserted_at]
      true -> query
    end

    query = from u in query,
      limit: ^limit, offset: ^offset, preload: ^preload

    {Repo.all(query), Repo.one(count_query)}
  end

  def get_user id, preload \\ []
  def get_user {:pubkey, pubkey}, preload do
    Repo.one(from u in User,
      where: u.pubkey==^pubkey,
      preload: ^preload)
  end
  def get_user {:hex_pubkey, pubkey}, preload do
    if NostrTools.Crypto.valid_hex?(pubkey, 32) do
      get_user {:pubkey, Base.decode16!(pubkey, case: :lower)}, preload
    end
  end
  def get_user {:id, id}, preload do
    Repo.one(from u in User,
      where: u.id==^id,
      preload: ^preload)
  end

  def get_or_create pubkey do
    user = get_user({:pubkey, pubkey})

    if user do
      user
    else
      %User{}
      |> User.changeset(%{pubkey: pubkey})
      |> Repo.insert!()
    end
  end

  def add_relay user, relay, opts \\ %{} do
    relay = normalize_relay(relay)
    if String.match?(relay, ~r(^wss://.+)) and String.length(relay) < 300 do
      relay = Relays.get_or_create(relay)
      user_relay = get_user_relay(user.id, relay.id) || %UserRelay{}
      user_relay
        |> UserRelay.changeset(%{
          user_id: user.id,
          relay_id: relay.id,
          recommended: (opts[:recommended] || user_relay.recommended),
          read: (opts[:read] || user_relay.read),
          write: (opts[:write] || user_relay.write),
          profile: (opts[:profile] || user_relay.profile),
          global: (opts[:global] || user_relay.global),
        })
        |> Repo.insert_or_update()

      if opts[:set_server_read] != nil and relay.read != opts[:set_server_read] do
        read = !String.match?(relay.url, ~r/filter\.nostr\.wine/) and opts[:set_server_read]
        Relays.set_read(relay.id, read)
      end
    end

  end

  def get_user_relay user_id, relay_id do
    Repo.one(from us in UserRelay,
      where: us.user_id==^user_id and us.relay_id==^relay_id
      )
  end

  def update_all_follower_count do
    query = from u in User, select: u.id, order_by: u.id
    ids = Repo.all(query)
    ids
    |> Enum.with_index()
    |> Enum.map(fn {user_id, i} ->
      IO.puts("#{i} - #{user_id}" )
      recalculate_follower_counts(user_id)
    end)
  end

  def recalculate_follower_counts user_id do
    user = get_user({:id, user_id})
    query = from f in Follower, select: count("*")
    follower_query = from f in query, where: f.followed_id==^user_id
    following_query = from f in query, where: f.follower_id==^user_id
    if user do
      follower_count = Repo.one(follower_query)
      following_count = Repo.one(following_query)
      user
      |> User.changeset(%{
        follower_count: follower_count,
        following_count: following_count
      })
      |> Repo.update()
    end
  end

  def trim str, len do
    if str do
      String.slice(str, 0..(len-1))
    else
      str
    end
  end

  def create_session user_id do
    attrs = %{
      uuid: UUID.uuid1(),
      user_id: user_id
    }

    %Session{}
    |> Session.changeset(attrs)
    |> Repo.insert()
  end

  def get_session user_id, uuid do
    Repo.one(from s in Session, where: s.user_id==^user_id and s.uuid==^uuid, preload: [:user])
  end

  def create_rememberable user_id do
    series = random_string(50)
    token = random_string(50)
    token_hash = hash_token(token)
    params = %{
      user_id: user_id,
      series_hash: series,
      token_hash: token_hash,
      token_created_at: Timex.now()
    }
    rememberable = %Rememberable{}
      |> Rememberable.changeset(params)
      |> Repo.insert()
      |> case do
        {:ok, _} ->
          {:ok, series, token}
        {:error, reason} -> {:error, reason}
      end
  end

  def get_rememberable user_id, series, token do
    query = from r in Rememberable, where: r.user_id==^user_id and r.series_hash==^series
    rememberable = Repo.one(query)
    if !!rememberable and hash_token(token) == rememberable.token_hash do
      new_token = random_string(50)
      token_hash = hash_token(new_token)
      rememberable
      |> Rememberable.changeset(%{token_hash: token_hash, token_created_at: Timex.now()})
      |> Repo.update()
      |> case do
        {:ok, _} -> {:ok, series, new_token}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  def delete_sessions user_id do
    Repo.delete_all(from s in Session, where: s.user_id==^user_id)
  end

  def delete_rememberables user_id do
    Repo.delete_all(from r in Rememberable, where: r.user_id==^user_id)
  end

  def delete_old_sessions_and_rememberables do
    one_day_ago = Timex.shift(Timex.now(), days: -(1))
    thirty_days_ago = Timex.shift(Timex.now(), days: -(30))
    Repo.delete_all(from s in Session, where: s.inserted_at < ^one_day_ago)
    Repo.delete_all(from r in Rememberable, where: r.updated_at < ^thirty_days_ago)
  end

  def random_string(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, length)
  end

  def hash_token string do
    Base.encode64(:crypto.hash(:sha256, string))
  end

  def normalize_relay(url) do
    url = String.trim(url)
    |> String.trim_trailing("/")
    |> String.downcase()

    Regex.replace(~r/\s/, url, "")
  end

  def get_follow_map users, user_id do
    ids = Enum.map(users, fn u -> u.id end)
    query = from f in Follower,
      where: f.follower_id == ^user_id,
      where: f.followed_id in ^ids

    followers = Repo.all(query)
    Map.new(followers, fn f ->
      {f.followed_id, true}
    end)
  end

end
