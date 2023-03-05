defmodule AppWeb.ControllerHelpers do

  alias App.Posts
  alias App.Users

  def pagination params do
    offset = if params["offset"] do
      case Integer.parse(params["offset"]) do
        {o, _} -> o
        _ -> 0
      end
    else
      0
    end
    limit = if params["limit"] do
      case Integer.parse(params["limit"]) do
        {l, _} -> if l < 100, do: l, else: 100
        _ -> 50
      end
    else
      50
    end
    {limit, offset}
  end

  def json(conn, data) do
    conn
    |> Plug.Conn.put_resp_header("content-type", "application/json; charset=utf-8")
    |> Plug.Conn.send_resp(200, Jason.encode!(data))
  end

  def get_like_map(conn, posts) do
    replies = Enum.flat_map(posts, fn post ->
      if Ecto.assoc_loaded?(post.reply) && !!post.reply do
        [post.reply]
      else
        []
      end
    end)
    posts = posts ++ replies
    if conn.assigns[:current_user] do
      Posts.get_like_map(posts, conn.assigns[:current_user].id)
    end
  end

  def get_follow_map(conn, users) do
    if conn.assigns[:current_user] do
      Users.get_follow_map(users, conn.assigns[:current_user].id)
    end
  end
end
