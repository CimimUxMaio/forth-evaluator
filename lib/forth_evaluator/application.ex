defmodule ForthEvaluator.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ForthEvaluatorWeb.Telemetry,
      ForthEvaluator.Repo,
      {DNSCluster, query: Application.get_env(:forth_evaluator, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ForthEvaluator.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: ForthEvaluator.Finch},
      # Start a worker by calling: ForthEvaluator.Worker.start_link(arg)
      # {ForthEvaluator.Worker, arg},
      # Start to serve requests, typically the last entry
      ForthEvaluatorWeb.Endpoint,
      {Task.Supervisor, name: ForthEvaluator.EvalSupervisor}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ForthEvaluator.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ForthEvaluatorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
