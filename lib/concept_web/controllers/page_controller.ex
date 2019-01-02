defmodule ConceptWeb.PageController do
  use ConceptWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
