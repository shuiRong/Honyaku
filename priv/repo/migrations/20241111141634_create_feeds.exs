defmodule Honyaku.Repo.Migrations.CreateFeeds do
  use Ecto.Migration

  def change do
    create table(:feeds) do
      add :url, :string
      add :source_lang, :string
      add :target_lang, :string

      timestamps(type: :utc_datetime)
    end
  end
end