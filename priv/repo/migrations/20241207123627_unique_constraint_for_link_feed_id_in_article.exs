defmodule Honyaku.Repo.Migrations.UniqueConstraintForLinkFeedIdInArticle do
  use Ecto.Migration

  def change do
    create unique_index(:articles, [:link, :feed_id])
  end
end
