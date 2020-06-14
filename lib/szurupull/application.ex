defmodule Szurupull.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Szurupull.Repo,
      # Start the Telemetry supervisor
      SzurupullWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Szurupull.PubSub},
      # Start the Endpoint (http/https)
      SzurupullWeb.Endpoint,
      # Start a worker by calling: Szurupull.Worker.start_link(arg)
      # {Szurupull.Worker, arg}
      {Szurupull.UploaderServer, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Szurupull.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    SzurupullWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
