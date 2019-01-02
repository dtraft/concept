defmodule Concept.ConceptsTest do
  use Concept.DataCase

  alias Concept.Concepts

  describe "project" do
    alias Concept.Concepts.Project

    @valid_attrs %{data: %{}}
    @update_attrs %{data: %{}}
    @invalid_attrs %{data: nil}

    def project_fixture(attrs \\ %{}) do
      {:ok, project} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Concepts.create_project()

      project
    end

    test "list_project/0 returns all project" do
      project = project_fixture()
      assert Concepts.list_project() == [project]
    end

    test "get_project!/1 returns the project with given id" do
      project = project_fixture()
      assert Concepts.get_project!(project.id) == project
    end

    test "create_project/1 with valid data creates a project" do
      assert {:ok, %Project{} = project} = Concepts.create_project(@valid_attrs)
      assert project.data == %{}
    end

    test "create_project/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Concepts.create_project(@invalid_attrs)
    end

    test "update_project/2 with valid data updates the project" do
      project = project_fixture()
      assert {:ok, %Project{} = project} = Concepts.update_project(project, @update_attrs)
      assert project.data == %{}
    end

    test "update_project/2 with invalid data returns error changeset" do
      project = project_fixture()
      assert {:error, %Ecto.Changeset{}} = Concepts.update_project(project, @invalid_attrs)
      assert project == Concepts.get_project!(project.id)
    end

    test "delete_project/1 deletes the project" do
      project = project_fixture()
      assert {:ok, %Project{}} = Concepts.delete_project(project)
      assert_raise Ecto.NoResultsError, fn -> Concepts.get_project!(project.id) end
    end

    test "change_project/1 returns a project changeset" do
      project = project_fixture()
      assert %Ecto.Changeset{} = Concepts.change_project(project)
    end
  end
end
