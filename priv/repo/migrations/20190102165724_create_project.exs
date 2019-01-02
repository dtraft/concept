defmodule Concept.Repo.Migrations.CreateProject do
  use Ecto.Migration

  def change do
    create table(:project, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :data, :map

      timestamps()
    end

  end
end
