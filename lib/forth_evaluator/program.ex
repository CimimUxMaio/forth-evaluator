defmodule ForthEvaluator.Program do
  use Ecto.Schema

  alias ForthEvaluator.{Parser, Evaluator}

  import Ecto.Changeset

  schema "programs" do
    field(:status, :string)
    field(:text, :string)
    field(:output, :string, default: "")
    field(:last_update, :utc_datetime)

    timestamps(type: :utc_datetime)
  end

  def changeset(program, attrs \\ %{}) do
    program
    |> cast(attrs, [:status, :text, :output, :last_update])
    |> validate_required([:status, :text])
    |> validate_inclusion(:status, ["RUNNING", "DONE"])
    |> put_change(:last_update, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  def run(program, stack, dictionary) do
    output =
      case Parser.parse_program(program.text) do
        :error ->
          "Syntax Error"

        tokens ->
          Evaluator.evaluate(tokens, stack, dictionary)
      end

    %ForthEvaluator.Program{program | output: output}
  end
end
