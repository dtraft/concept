defmodule Concept.Repo do
  use Ecto.Repo,
    otp_app: :concept,
    adapter: Ecto.Adapters.Postgres
end
