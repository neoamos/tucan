defmodule AppWeb.UserController do
  use AppWeb, :controller

  alias App.Users
  alias App.Storage
  alias App.Client.ProcessingWorker

  def current_user conn, _params do
    user = Users.get_user({:id, conn.assigns.current_user.id}, [:relays, relays: :relay])
    render(conn, "user.json", user: user)
  end

  def metadata conn, _params do
    user = conn.assigns.current_user
    {metadata, _} = Storage.get_latest_event(0, user.pubkey)
    if metadata do
      ControllerHelpers.json(conn, metadata)
    else
      error(conn, 404, "No metadata")
    end
  end

  def contact_list conn, _params do
    user = conn.assigns.current_user
    {contact_list, _} = Storage.get_latest_event(3, user.pubkey)
    if contact_list do
      ControllerHelpers.json(conn, contact_list)
    else
      error(conn, 404, "No metadata")
    end
  end

  def user(conn, %{"pubkey" => pubkey}) do
    pubkey = Base.decode16!(pubkey, case: :lower)
    user = Users.get_user({:pubkey, pubkey})
    if user do
      follow_map = ControllerHelpers.get_follow_map(conn, [user])
      render conn, "user.json", user: user, followed: follow_map[user.id]
    else
      error(conn, 404, "Post not found")
    end
  end

  def users(conn, params) do
    filters = %{
      following: Users.get_user({:hex_pubkey, params["following"]}),
      followed: Users.get_user({:hex_pubkey, params["followed"]})
    }
    {limit, offset} = ControllerHelpers.pagination(params)


    {users, count} = Users.get_users(limit, offset, filters, nil)
    follow_map = ControllerHelpers.get_follow_map(conn, users)

    render conn, "users.json", users: users, count: count, follow_map: follow_map
  end


  def login conn, %{"auth" => auth} do
    with {:ok, json} <- Jason.decode(auth),
         {:ok, event} <- NostrTools.Event.create(json)
    do
      if NostrTools.Event.valid?(event) and event.kind==188102 and event.content=="Authenticate me! Jskah5XozzaPfnE3WQ5R" do
        now = DateTime.utc_now() |> DateTime.to_unix()
        auth_at = DateTime.to_unix(event.created_at)
        if abs(auth_at-now) < 120 do
          user = Users.get_or_create(event.pubkey)
          conn = create_session(conn, user.id)
            |> create_remember_me(user.id)
          user = Users.get_user({:id, user.id}, [:relays, relays: :relay])
          render(conn, "user.json", user: user)
        else
          error(conn, 400, "Auth expired")
        end
      else
        error(conn, 400, "Bad auth event")
      end
    else
      _ -> error(conn, 400, "Bad auth event")
    end
  end

  def logout conn, _params do
    if conn.assigns[:current_user] do
      Users.delete_sessions(conn.assigns[:current_user].id)
      Users.delete_rememberables(conn.assigns[:current_user].id)
    end
    conn
    |> delete_resp_cookie("remember-me", encrypted: true)
    # |> delete_resp_cookie("client", encrypted: true)
    |> clear_session()

    render(conn, "ok.json", message: "Logged out")
  end

  def create_session(conn, user_id) do
    case Users.create_session(user_id) do
      {:ok, session} ->
        conn
        |> put_session(:user_id, user_id)
        |> put_session(:uuid, session.uuid)
      _ -> conn
    end
  end

  def create_remember_me(conn, user_id) do
    case Users.create_rememberable(user_id) do
      {:ok, series, token} ->
        put_resp_cookie(conn, "remember-me", %{user_id: user_id, series: series, token: token}, encrypt: true, max_age: 30*24*60*60)
      _ -> conn
    end
  end

  def search(conn, %{"s" => term}) do
    filters = %{
      search: term
    }

    {users, count} = Users.get_users(20, 0, filters, nil)

    render conn, "users.json", users: users, count: count
  end

  def error(conn, code, message) do
    conn
    |> put_status(code)
    |> put_view(AppWeb.ErrorView)
    |> render("#{code}.json", message: message)
  end
end
