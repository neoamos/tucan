defmodule AppWeb.ApiController do
  use AppWeb, :controller

  alias App.Posts
  alias App.Users
  alias App.Storage

  def post(conn, %{"post_id" => post_id}) do
    post_id = Base.decode16!(post_id, case: :lower)
    post = Posts.get_post({:event_id, post_id}, [:user, :user_mentions, :received_by, :post_mentions, :reply,
      :root_reply, root_reply: [:user, :received_by],
      reply: [:user, :user_mentions, :post_mentions, user_mentions: [:mentioned], post_mentions: [:mentioned]],
      user_mentions: [:mentioned], post_mentions: [:mentioned]])
    like_map = ControllerHelpers.get_like_map(conn, [post])
    if post do
      render conn, "post.json", post: post, liked: like_map[post.id]
    else
      error(conn, 404, "Post not found")
    end
  end

  def posts conn, params do
    filters = %{
      with_replies: params["with_replies"],
      count: params["count"]
    }
    filters = if params["before"] do
      case Integer.parse(params["before"]) do
        {time, _} -> Map.put(filters, :before, DateTime.from_unix!(time))
        _ -> filters
      end
    else
      filters
    end

    filters = case params["feed"] do
      "Following" ->
        filters
        |> Map.put(:followed_by, conn.assigns[:current_user].id)
        # |> Map.put(:with_replies, true)
      "Friends of Friends" ->
        filters
        |> Map.put(:extended_followed_by, conn.assigns[:current_user].id)
      "Global" ->
        filters
        |> Map.put(:from_relay, 320)
      _ -> filters
    end

    filters = if params["pubkey"] do
      user = Users.get_user({:hex_pubkey, params["pubkey"]})
      if user do
        Map.put(filters, :user_id, user.id)
      else
        filters
      end
    else
      filters
    end

    {limit, offset} = ControllerHelpers.pagination(params)

    {posts, count} = Posts.get_posts(limit, offset, :created_at, filters,
      [:user, :user_mentions, :post_mentions, :reply,
      reply: [:user, :user_mentions, :post_mentions, user_mentions: [:mentioned], post_mentions: [:mentioned]],
      user_mentions: [:mentioned], post_mentions: [:mentioned]])

    like_map = ControllerHelpers.get_like_map(conn, posts)

    render conn, "posts.json", posts: posts, count: count, like_map: like_map
  end

  def likes conn, params do
    user = Users.get_user({:hex_pubkey, params["pubkey"]})
    if user do
      {limit, offset} = ControllerHelpers.pagination(params)
      {posts, count} = Posts.get_liked_posts(user.id, limit, offset, [:user])
      like_map = ControllerHelpers.get_like_map(conn, posts)
      render conn, "posts.json", posts: posts, count: count, like_map: like_map
    else
      error(conn, 404, "User not found")
    end
  end

  def replies(conn, %{"post_id" => post_id} = params) do
    post_id = Base.decode16!(post_id, case: :lower)
    post = Posts.get_post({:event_id, post_id})
    if post do
      # {limit, offset} = ControllerHelpers.pagination(params)
      {replies, count} = Posts.get_replies(post, 100, 0, [:user, :user_mentions, :post_mentions, :reply,
        reply: [:user, :user_mentions, :post_mentions, user_mentions: [:mentioned], post_mentions: [:mentioned]],
        user_mentions: [:mentioned], post_mentions: [:mentioned]])
      like_map = ControllerHelpers.get_like_map(conn, replies)
      render conn, "posts.json", posts: replies, count: count, like_map: like_map
    else
      error(conn, 404, "Post not found")
    end
  end

  def reply_chain(conn, %{"post_id" => post_id}) do
    post_id = Base.decode16!(post_id, case: :lower)
    post = Posts.get_post({:event_id, post_id})
    if post do
      replies = Posts.get_reply_chain(post.id, [:user, :user_mentions, :post_mentions, :reply,
        reply: [:user, :user_mentions, :post_mentions, user_mentions: [:mentioned], post_mentions: [:mentioned]],
        user_mentions: [:mentioned], post_mentions: [:mentioned]])
      like_map = ControllerHelpers.get_like_map(conn, replies)
      render conn, "posts.json", posts: replies, count: 0, like_map: like_map
    else
      error(conn, 404, "Post not found")
    end
  end

  def post_event(conn, %{"event" => event}) do
    case NostrTools.Event.create(event) do
      {:ok, event} ->
        case Storage.store(event) do
          {:ok, es} ->
            App.Client.ProcessingWorker.process_event(es)
            render(conn, "ok.json", message: "Event posted")
          _ -> error(conn, 400, "Bad event")
        end
      _ -> error(conn, 400, "Bad event")
    end
  end

  def error(conn, code, message) do
    conn
    |> put_status(code)
    |> put_view(AppWeb.ErrorView)
    |> render("#{code}.json", message: message)
  end

end
