defmodule Honyaku.Repo.Migrations.UniqueConstraintForUrlInFeedSchema do
  use Ecto.Migration

  def change do
    create unique_index(:feeds, [:url])
  end
end
