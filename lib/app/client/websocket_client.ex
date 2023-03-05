defmodule App.Client.WebSocketClient do
  @moduledoc false
  use WebSockex
  alias App.Client.WebSocketSupervisor

  alias NostrTools.Message
  alias NostrTools.Event
  alias NostrTools.Filter

  alias App.Users
  alias App.Storage

  alias App.Repo

  def start_link(url, state) do
    WebSockex.start_link(url, __MODULE__, state, name: via_tuple(url), extra_headers: [{"User-Agent", "tucan.to relay aggregator"}])
  end

  # Client API

  def send url, message do
    WebSockex.send_frame(via_tuple(url), {:text, message})
  end

  def send_async(url, message) do
    WebSockex.cast(via_tuple(url), {:send, {:text, message}})
  end

  def disconnect url do
    WebSockex.cast(via_tuple(url), :disconnect)
  end

  def connect url do
    WebSocketSupervisor.start_child(url)
  end

  def request url, sub_id, filter do
    __MODULE__.send(url, Jason.encode!(NostrTools.Message.req(sub_id, filter)))
  end

  def request_async url, sub_id, filter do
    __MODULE__.send_async(url, Jason.encode!(NostrTools.Message.req(sub_id, filter)))
  end

  def close url, sub_id do
    __MODULE__.send(url, Jason.encode!(NostrTools.Message.close(sub_id)))
  end

  def scrape url do
    sub_id = :crypto.strong_rand_bytes(10) |> Base.url_encode64 |> binary_part(0, 10)
    f = %Filter{since: 1672709517}
    connect(url)
    request(url, sub_id, f)
  end

  def connected? url do
    case Registry.lookup(:websocket_clients, url) do
      [{pid, _}] -> true
      _ -> false
    end
  end

  # Server handlers

  def handle_frame({type, msg}, state) do
    # IO.inspect(state)
    # IO.puts "Received Message - Type: #{inspect type} -- Message: #{inspect msg}"
    case Jason.decode(msg) do
      {:ok, ["EVENT", _, json]} ->
        case NostrTools.Event.create(json) do
          {:ok, event} ->
            if Event.valid?(event) do
              now = DateTime.utc_now() |> DateTime.to_unix()
              created_at = DateTime.to_unix(event.created_at)
              if created_at < now+60 do
                Storage.store(event, relays: [state.url])
              else
                IO.puts("Received an event #{created_at-now}s in the future")
              end
            else
              IO.puts("Receive invalid event: #{inspect json}")
            end
          other -> IO.inspect(other)
        end
      _ -> nil
    end
    {:ok, state}
  end

  def handle_cast({:send, {type, msg} = frame}, state) do
    {:reply, frame, state}
  end

  def handle_cast(:disconnect, state) do
    exit(:normal)
  end

  def handle_connect(conn, state) do
    now = DateTime.utc_now() |> DateTime.to_unix()
    sub_id = random_string(10)
    request_async(state.url, sub_id, %Filter{since: now-120, kinds: [0,1,3,5,6,7,1984,9734,9735,10002]})
    state = Map.put(state, :sub_id, sub_id)
    {:ok, state}
  end

  def terminate(reason, state) do
    IO.puts("Socket Terminating. reason: #{inspect reason} state: #{inspect state}")
    exit(:normal)
  end

  defp via_tuple url do
    {:via, Registry, {:websocket_clients, url}}
  end

  def random_string(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, length)
  end
end
