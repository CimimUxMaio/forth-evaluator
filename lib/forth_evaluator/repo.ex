defmodule ForthEvaluator.Repo do
  use Ecto.Repo,
    otp_app: :forth_evaluator,
    adapter: Ecto.Adapters.Postgres
end
