defmodule Honyaku.Repo do
  use Ecto.Repo,
    otp_app: :honyaku,
    adapter: Ecto.Adapters.Postgres
end
