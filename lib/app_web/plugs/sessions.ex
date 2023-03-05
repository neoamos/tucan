defmodule AppWeb.Plugs.Users.Session do
  import Plug.Conn
  import AppWeb.Gettext

  alias App.Users

  def init(options) do

    options
  end

  def call(conn, opts) do
    conn = conn
    |> get_user_from_session()
    |> get_user_from_rememberable()

    if !conn.assigns[:current_user] and opts[:protected] do
      conn
      |> halt()
    else
      conn
    end
  end

  defp get_user_from_session conn do
    case get_session(conn, :uuid) do
      nil -> conn
      uuid ->
        user_id = get_session(conn, :user_id)
        session = Users.get_session(user_id, uuid)
        if session do
          assign(conn, :current_user, session.user)
        else
          conn
        end
    end
  end

  defp get_user_from_rememberable conn do
    if conn.assigns[:current_user] do
      conn
    else
      conn = fetch_cookies(conn, encrypted: ~w(remember-me))
      case conn.cookies["remember-me"] do
        %{series: series, token: token, user_id: user_id} ->
          # IO.inspect("old token: #{token}")
          case Users.get_rememberable(user_id, series, token) do
            {:ok, series, token} ->

              IO.inspect("new token: #{token}")
              user = Users.get_user({:id, user_id})
              conn = conn
              |> put_resp_cookie("remember-me", %{user_id: user_id, series: series, token: token}, encrypt: true, max_age: 30*24*60*60)
              |> assign(:current_user, user)

              case Users.create_session(user_id) do
                {:ok, session} ->
                  conn
                  |> clear_session()
                  |> put_session(:user_id, user_id)
                  |> put_session(:uuid, session.uuid)
                _ -> conn
              end
            _ -> conn
          end
        _ -> conn
      end
    end
  end

end
