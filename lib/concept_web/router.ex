defmodule ConceptWeb.Router do
  use ConceptWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ConceptWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/api", ConceptWeb do
    pipe_through :api

    resources "/project", ProjectController, except: [:index, :delete]
  end
end
