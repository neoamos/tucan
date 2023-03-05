defmodule App.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      App.Repo,
      # Start the Telemetry supervisor
      AppWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: App.PubSub},
      # Start the Endpoint (http/https)
      AppWeb.Endpoint,
      # Start a worker by calling: App.Worker.start_link(arg)
      # {App.Worker, arg}

      # Websocket clients
      {App.Client.WebSocketSupervisor, []},
      {Registry, [keys: :unique, name: :websocket_clients]}
    ]

    # Schedule event workers
    children = if System.get_env("WORKERS") do
      children ++ [
        %{
          id: :event_processing,
          start: {App.Task, :start_link, [%{job: &App.Client.ProcessingWorker.process_events/0, args: [], interval: 0.0014, name: "event_processing" }]}
        },
        %{
          id: :nip5_check,
          start: {App.Task, :start_link, [%{job: &App.Client.ProcessingWorker.verify_nip5/0, args: [], interval: 0.0014, name: "nip5_check" }]}
        },
        %{
          id: :connect_relays,
          start: {App.Task, :start_link, [%{job: &App.Client.ProcessingWorker.connect_relays/0, args: [], interval: 1/60, name: "connect_relays" }]}
        }
      ]
    else
      children
    end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: App.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
