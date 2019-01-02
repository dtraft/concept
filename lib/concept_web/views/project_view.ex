defmodule ConceptWeb.ProjectView do
  use ConceptWeb, :view
  alias ConceptWeb.ProjectView

  def render("index.json", %{project: project}) do
    render_many(project, ProjectView, "project.json")
  end

  def render("show.json", %{project: project}) do
    render_one(project, ProjectView, "project.json")
  end

  def render("project.json", %{project: project}) do
    %{id: project.id, data: project.data}
  end
end
