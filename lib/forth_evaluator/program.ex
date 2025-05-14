defmodule ForthEvaluator.Program do
  use Ecto.Schema

  alias ForthEvaluator.{Parser, Evaluator}

  import Ecto.Changeset

  schema "programs" do
    field(:status, :string)
    field(:text, :string)
    field(:output, :string, default: "")

    timestamps(type: :utc_datetime)
  end

  def changeset(program, attrs \\ %{}) do
    program
    |> cast(attrs, [:status, :text, :output])
    |> validate_required([:status, :text])
    |> validate_inclusion(:status, ["RUNNING", "DONE"])
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
