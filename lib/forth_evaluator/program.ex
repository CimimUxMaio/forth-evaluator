defmodule ForthEvaluator.Program do
  use Ecto.Schema

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
end
