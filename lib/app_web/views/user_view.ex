defmodule AppWeb.UserView do
  use AppWeb, :view

  alias AppWeb.ViewHelpers

  def render("user.json", %{user: user} = params) do
    ViewHelpers.user(user, followed: params[:followed])
  end

  def render("users.json", %{users: users, count: count} = params) do
    follow_map = params[:follow_map] || %{}
    users = Enum.map(users, fn user ->
      ViewHelpers.user(user, followed: follow_map[user.id])
    end)
    %{
      count: count,
      users: users
    }
  end

  def render("ok.json", %{message: message}) do
    %{ok: message}
  end

end
