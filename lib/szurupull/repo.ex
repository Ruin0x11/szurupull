defmodule Szurupull.Repo do
  use Ecto.Repo,
    otp_app: :szurupull,
    adapter: Ecto.Adapters.Postgres
end
