defmodule Honyaku.Repo.Migrations.CreateArticles do
  use Ecto.Migration

  def change do
    create table(:articles) do
      add :link, :string
      add :title, :text
      add :language, :string
      add :original_published_at, :utc_datetime
      add :original_updated_at, :utc_datetime
      add :content, :map
      add :summary, :map
      add :feed_id, references(:feeds, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:articles, [:feed_id])
  end
end
