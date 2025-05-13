defmodule ForthEvaluator.Repo.Migrations.CreatePrograms do
  use Ecto.Migration

  def change do
    create table(:programs) do
      add(:status, :string)
      add(:text, :string)
      add(:output, :string)
      add(:last_update, :utc_datetime)

      timestamps(type: :utc_datetime)
    end
  end
end
