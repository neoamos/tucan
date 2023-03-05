defmodule AppWeb.ApiView do
  use AppWeb, :view

  alias AppWeb.ViewHelpers

  def render("post.json", %{post: post} = params) do
    ViewHelpers.post(post, liked: params[:liked])
  end

  def render("user.json", %{user: user}) do
    ViewHelpers.user(user)
  end

  def render("timeline.json", %{posts: posts}) do
    render("posts.json", posts: posts)
  end

  def render("posts.json", %{posts: posts, count: count} = params) do
    like_map = params[:like_map] || %{}
    posts = Enum.map(posts, fn post ->
      post_map = ViewHelpers.post(post, liked: like_map[post.id])
      if Ecto.assoc_loaded?(post.reply) and !!post.reply and !!post.reply.event_storage_id do
        Map.put(post_map, :reply_to, ViewHelpers.post(post.reply, liked: like_map[post.reply.id]))
      else
        post_map
      end
    end)
    %{
      count: count,
      posts: posts
    }
  end

  def render("ok.json", %{message: message}) do
    %{ok: message}
  end

end
