defmodule Honyaku.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HonyakuWeb.Telemetry,
      Honyaku.Repo,
      {DNSCluster, query: Application.get_env(:honyaku, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Honyaku.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Honyaku.Finch},
      # Start a worker by calling: Honyaku.Worker.start_link(arg)
      # {Honyaku.Worker, arg},
      # Start to serve requests, typically the last entry
      HonyakuWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Honyaku.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HonyakuWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
