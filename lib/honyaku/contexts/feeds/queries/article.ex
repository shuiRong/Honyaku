defmodule Honyaku.Feeds.Queries.Article do
  alias Honyaku.Repo
  alias Honyaku.Feeds.Article

  def get_article(link, feed_id) do
    Repo.get_by(Article, link: link, feed_id: feed_id)
  end

  def insert_article(attrs) do
    %Article{}
    |> Article.changeset(attrs)
    |> Repo.insert()
  end
end
