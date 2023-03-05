defmodule App.Posts do
  import Ecto.Query, warn: false
  alias App.Repo

  alias App.Post
  alias App.Post.Like
  alias App.Post.UserMention
  alias App.Post.PostMention
  alias App.Post.PostRelay
  alias App.User
  alias App.Users
  alias NostrTools.Crypto
  alias App.Storage.EventStorage
  alias App.Storage.EventRelay
  alias App.Storage
  alias App.Relays
  alias App.User.Follower

  def parse_post event_storage, event, opts \\ %{} do
    post = get_post({:event_id, event.id}, [:post_mentions, :user_mentions]) || %Post{}
    if true or !post.event_storage_id do

      # Get PostMentions and create them
      {root, reply, repost, mentioned_posts} = get_post_mentions(event)
      post_mentions = create_post_mentions(mentioned_posts, post.id)

      # Get UserMentions and create them
      user_mention_tags = get_user_mentions(event)
      user_mentions = create_user_mentions(user_mention_tags, post.id)

      # Get or create User
      user = Users.get_or_create(event.pubkey)

      # Update or insert post
      params = %{
        user_id: user.id,
        event_storage_id: event_storage.id,
        event_id: event.id,
        content: event.content,
        reply_id: (if reply, do: reply.id),
        root_reply_id: (if root, do: root.id),
        repost_id: (if repost, do: repost.id),
        created_at: event.created_at
      }
      post
      |> Post.changeset(params)
      |> Ecto.Changeset.put_assoc(:post_mentions, post_mentions)
      |> Ecto.Changeset.put_assoc(:user_mentions, user_mentions)
      |> Repo.insert_or_update()
      |> case do
        {:ok, post} ->
          Storage.set_processed(event_storage, "ok")
          post = Repo.preload(post, [:reply])
          if post.reply, do: update_reply_count(post.reply)
        other ->
          Storage.set_processed(event_storage, "error")
          other
      end

    end

    # if opts[:relay], add_relay(post, opts[:relay])
  end

  def parse_posts limit do
    query = from es in EventStorage,
      where: es.kind==1, # and is_nil(es.processed_at),
      order_by: es.inserted_at,
      limit: ^limit,
      preload: [:tags]
    event_storages = Repo.all(query)

    Enum.map(event_storages, fn es ->
      e = Storage.event_from_storage(es)
      parse_post(es, e)
    end)
  end

  def parse_reaction event_storage, event do
    user = Users.get_or_create(event.pubkey)

    [_, note_id | _rest] = event.tags
      |> Enum.reverse()
      |> Enum.find(fn t ->
        Enum.at(t, 0) == "e" and Crypto.valid_hex?(Enum.at(t, 1), 32)
      end)

    post = get_or_create(Base.decode16!(note_id, case: :lower))

    like = get_like(user.id, post.id)
    attrs = %{
      user_id: user.id,
      post_id: post.id,
      event_storage_id: event_storage.id,
      created_at: event.created_at,
      positive: (event.content != "-")
    }

    (like || %Like{})
    |> Like.changeset(attrs)
    |> Repo.insert_or_update()
    |> case do
      {:ok, like} ->
        Storage.set_processed(event_storage, "ok")
        update_like_count(post)
      other ->
        Storage.set_processed(event_storage, "error")
        IO.inspect(other)
        other
    end

  end

  def parse_reactions limit do
    query = from es in EventStorage,
      where: es.kind==7, # and is_nil(es.processed_at),
      order_by: es.inserted_at,
      limit: ^limit,
      preload: [:tags]
    event_storages = Repo.all(query)

    Enum.map(event_storages, fn es ->
      e = Storage.event_from_storage(es)
      parse_reaction(es, e)
    end)
  end

  def update_like_count post do
    query = from l in Like,
      where: l.post_id==^post.id,
      select: count("*")
    like_count = Repo.one(query)
    post
    |> Ecto.Changeset.change(like_count: like_count)
    |> Repo.update()
  end

  def get_like(user_id, post_id) do
    query = from l in Like,
      where: l.user_id==^user_id and l.post_id==^post_id
    Repo.one(query)
  end

  def update_reply_count post do
    query = from p in Post,
      select: count("*"),
      where: p.reply_id==^post.id

    count = Repo.one(query)
    post
    |> Ecto.Changeset.change(reply_count: count)
    |> Repo.update()
  end

  def get_or_create event_id do
    post = get_post({:event_id, event_id})
    if post do
      post
    else
      %Post{}
      |> Post.changeset(%{event_id: event_id})
      |> Repo.insert!()
    end
  end
  def get_or_create(event_id) when is_nil(event_id), do: nil

  def create_post_mentions mentioned_posts, post_id do
    Enum.map(mentioned_posts, fn {post, pos, type} ->
      post_mention = nil
      #   if post_id, do: Repo.one(from pm in PostMention,
      #   where: pm.mentioned_by_id == ^post_id,
      #   where: pm.mentioned_id == ^post.id and pm.position == ^pos and pm.type == ^type
      # )
      post_mention || (%PostMention{
        mentioned_id: post.id,
        position: pos,
        type: type
      }
      |> PostMention.changeset())
    end)
  end

  def create_user_mentions mentioned_users, post_id do
    Enum.map(mentioned_users, fn {user, pos} ->
      user_mention = if post_id, do: Repo.one(from um in UserMention,
        where: um.mentioned_by_id == ^post_id,
        where: um.mentioned_id == ^user.id and um.position == ^pos
      )
      user_mention || (%UserMention{
            mentioned_id: user.id,
            position: pos
      }
      |> UserMention.changeset())
    end)
  end

  def create_hashtags tags do

  end

  def get_post_mentions event do
    tags = event.tags
      |> Enum.filter(fn t -> length(t) >= 2 end)
      |> Enum.with_index()
      |> Enum.filter(fn {[t, id | _], i} -> t=="e" and Crypto.valid_hex?(id, 32) end)

    marked = Enum.any?(tags, fn {tag, i} ->
      length(tag)>=4 and (
        Enum.at(tag, 3) == "root" or
        Enum.at(tag, 3) == "reply" or
        Enum.at(tag, 3) == "mention"
      )
    end)

    # Marked mentions
    {root, reply} = if marked do
      root = Enum.find(tags, fn {tag, i} ->
          length(tag)>=4 and Enum.at(tag, 3) == "root"
      end)

      reply = Enum.find(tags, fn {tag, i} ->
        length(tag)>=4 and Enum.at(tag, 3) == "reply"
      end)
      {root, reply}
    else
      root = Enum.at(tags, 0)
      reply = Enum.at(tags, -1)
      {root, reply}
    end

    root = case root do
      {root, _} -> get_or_create(Enum.at(root, 1) |> Base.decode16!(case: :lower))
      _ -> nil
    end
    reply = case reply do
      {reply, _} -> get_or_create(Enum.at(reply, 1) |> Base.decode16!(case: :lower))
      _ -> nil
    end
    reply = reply || root


    mentions = Enum.map(tags, fn {[_, id | rest], i} ->
      post = get_or_create(id |> Base.decode16!(case: :lower))
      if length(rest) > 0 and Enum.at(rest, 0) != "" do
        add_relay(post, Enum.at(rest, 0), recommended: true, set_server_read: true)
      end
      {post, i, Enum.at(rest, 1)}
      end)

    repost = Enum.find_value(mentions, fn {p, _, type} -> if type=="mention", do: p end)

    {root, reply, repost, mentions}
  end

  def get_user_mentions event do
    tags = event.tags
      |> Enum.filter(fn t-> length(t)>=2 end)
      |> Enum.with_index()
      |> Enum.filter(fn {[t, id | _], i} -> t=="p" and Crypto.valid_hex?(id, 32) end)
      |> Enum.map(fn {[t, id | rest], i} ->
        user = (Users.get_or_create(id |> Base.decode16!(case: :lower)))
        res = {Users.get_or_create(id |> Base.decode16!(case: :lower)), i}
        if length(rest) > 0 and Enum.at(rest, 0) != "" do
          Users.add_relay(user, Enum.at(rest, 0), recommended: true, set_server_read: true)
        end
        {user, i}
      end)
  end

  def get_post id, preload \\ []
  def get_post {:event_id, id}, preload do
    query = from p in Post,
      where: p.event_id == ^id,
      preload: ^preload
    Repo.one(query)
  end

  def get_post {:id, id}, preload do
    query = from p in Post,
      where: p.id == ^id,
      preload: ^preload
    Repo.one(query)
  end

  def get_posts limit, offset, order, filters, preload do
    now = DateTime.utc_now()
    query = from p in Post,
      where: not is_nil(p.event_storage_id) and p.created_at < ^now

    query = if filters[:with_replies] do
      query
    else
      from p in query, where: is_nil(p.reply_id)
    end

    query = if filters[:before] do
      from p in query, where: p.created_at < ^filters[:before]
    else
      query
    end

    query = if filters[:user_id] do
      from p in query, where: p.user_id==^filters[:user_id]
    else
      query
    end

    query = if filters[:liked] do
      from p in query, where: p.like_count>0
    else
      query
    end

    query = if filters[:from_relay] do
      from p in query,
        join: er in EventRelay, on: er.event_storage_id==p.event_storage_id,
        where: er.relay_id==^filters[:from_relay]
    else
      query
    end

    query = if filters[:followed_by] do
      from p in query,
        join: f in Follower, on: f.followed_id==p.user_id,
        where: f.follower_id==^filters[:followed_by]
    else
      query
    end

    # filters = Map.put(filters, :extended_followed_by, 2569)
    query = if filters[:extended_followed_by] do
      sq = from f in Follower,
        where: f.follower_id==^filters[:extended_followed_by],
        select: f.followed_id
      sq2 = from f in Follower,
        where: f.follower_id==^filters[:extended_followed_by],
        join: ff in Follower, on: ff.follower_id==f.followed_id,
        select: ff.followed_id,
        distinct: ff.followed_id,
        union: ^sq
      ids = Repo.all(sq2)

      from p in query,
        join: f in Follower, on: f.followed_id==p.user_id,
        join: ff in Follower, on: ff.followed_id==f.follower_id,
        where: ff.follower_id==^filters[:extended_followed_by],
        select: f.follower_id

      from p in query, where: p.user_id in ^ids #subquery(sq2)
    else
      query
    end

    count_query = from p in query, select: count("*")

    query = case order do
      :created_at -> from p in query, order_by: [desc: p.created_at]
      _ -> query
    end
    query = from p in query,
      limit: ^limit,
      offset: ^offset,
      preload: ^preload

    {Repo.all(query), (if filters[:count], do: Repo.one(count_query), else: 0)}
  end

  def get_liked_posts(user_id, limit, offset, preload \\ []) do
    query = from p in Post,
      where: not is_nil(p.event_storage_id),
      join: l in Like, on: l.post_id==p.id,
      where: l.user_id==^user_id

    count_query = from p in query, select: count("*")
    query = from [p,l] in query,
      order_by: [desc: l.created_at],
      limit: ^limit,
      offset: ^offset,
      preload: ^preload

    {Repo.all(query), Repo.one(count_query)}
  end

  def get_replies(post, limit, offset, preload \\ []) do
    query = from p in Post,
      where: p.reply_id==^post.id

    count_query = from p in query, select: count("*")
    query = from p in query,
      limit: ^limit,
      offset: ^offset,
      preload: ^preload

    {Repo.all(query), Repo.one(count_query)}
  end

  def get_reply_chain(post_id, preload \\ []) do
    initial_query = from p in Post, where: p.id==^post_id

    recursive_query = from p in Post,
      join: r in "replies", on: r.reply_id==p.id

    union_query =
      initial_query
      |> union_all(^recursive_query)

    query = "replies"
      |> recursive_ctes(true)
      |> with_cte("replies", as: ^union_query)
      |> select([c], c.id)

    chain = Repo.all(query)
      |> Enum.reverse()
      |> Enum.slice(0..-2)
    Repo.all(from p in Post, where: p.id in ^chain, preload: ^preload)
  end

  def add_relay post, relay, opts \\ %{} do
    if String.match?(relay, ~r(^wss://.+)) and String.length(relay) < 300 do
      relay = Users.normalize_relay(relay)
      relay = Relays.get_or_create(relay)
      post_relay = get_post_relay(post.id, relay.id) || %PostRelay{}
      post_relay
        |> PostRelay.changeset(%{
          post_id: post.id,
          relay_id: relay.id,
          recommended: (opts[:recommended] || post_relay.recommended),
        })
        |> Repo.insert_or_update()

      if opts[:set_server_read] != nil and relay.read != opts[:set_server_read] do
        read = !String.match?(relay.url, ~r/filter\.nostr\.wine/) and opts[:set_server_read]
        Relays.set_read(relay.id, read)
      end
    end
  end

  def get_post_relay post_id, relay_id do
    Repo.one(from pr in PostRelay,
      where: pr.post_id==^post_id and pr.relay_id==^relay_id
      )
  end

  def get_like_map posts, user_id do
    ids = Enum.map(posts, fn p -> p.id end)
    query = from l in Like,
      where: l.user_id == ^user_id,
      where: l.post_id in ^ids

    likes = Repo.all(query)
    Map.new(likes, fn l ->
      {l.post_id, true}
    end)
  end
end
