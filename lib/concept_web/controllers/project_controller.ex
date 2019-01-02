defmodule ConceptWeb.ProjectController do
  use ConceptWeb, :controller

  alias Concept.Concepts
  alias Concept.Concepts.Project

  action_fallback ConceptWeb.FallbackController

  def index(conn, _params) do
    project = Concepts.list_project()
    render(conn, "index.json", project: project)
  end

  def create(conn, project_params) do
    with {:ok, %Project{} = project} <- Concepts.create_project(project_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.project_path(conn, :show, project))
      |> render("show.json", project: project)
    end
  end

  def show(conn, %{"id" => id}) do
    project = Concepts.get_project!(id)
    render(conn, "show.json", project: project)
  end

  def update(conn, %{"id" => id} = project_params) do
    project = Concepts.get_project!(id)

    with {:ok, %Project{} = project} <- Concepts.update_project(project, project_params) do
      render(conn, "show.json", project: project)
    end
  end

  def delete(conn, %{"id" => id}) do
    project = Concepts.get_project!(id)

    with {:ok, %Project{}} <- Concepts.delete_project(project) do
      send_resp(conn, :no_content, "")
    end
  end
end
