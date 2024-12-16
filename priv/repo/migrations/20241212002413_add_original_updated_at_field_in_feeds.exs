defmodule Honyaku.Repo.Migrations.AddOriginalUpdatedAtFieldInFeeds do
  use Ecto.Migration

  def change do
    alter table(:feeds) do
      add :original_updated_at, :utc_datetime
    end
  end
end
