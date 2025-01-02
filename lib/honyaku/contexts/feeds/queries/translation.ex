defmodule Honyaku.Feeds.Queries.Translation do
  import Ecto.Query
  
  alias Honyaku.Repo
  alias Honyaku.Feeds.{Translation, Article}

  def get_translation(id) do
    Repo.get(Translation, id)
  end

  def insert_translation(attrs) do
    %Translation{}
    |> Translation.changeset(attrs)
    |> Repo.insert()
  end

  def preload_feed_and_articles_with_translations(saved_feed, article_ids) do
    query_articles =
      from a in Article,
        where: a.id in ^article_ids,
        preload: [:translations],
        order_by: [desc: a.original_updated_at]

    saved_feed
    |> Repo.preload([
      :translations,
      articles: query_articles
    ])
  end
end
