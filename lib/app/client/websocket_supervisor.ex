defmodule App.Client.WebSocketSupervisor do
  use DynamicSupervisor

  alias App.Client.WebSocketClient

  def start_link args do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init _args do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child url do
    DynamicSupervisor.start_child(
      __MODULE__,
      %{id: WebSocketClient, start: {WebSocketClient, :start_link, [url, %{url: url}]}, restart: :transient}
    )
  end

end