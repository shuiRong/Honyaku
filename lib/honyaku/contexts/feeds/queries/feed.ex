defmodule Honyaku.Feeds.Queries.Feed do
  alias Honyaku.Repo
  alias Honyaku.Feeds.Feed

  def get_feed_by_url(url) do
    Repo.get_by(Feed, url: url)
  end

  def insert_feed(attrs) do
    %Feed{}
    |> Feed.changeset(attrs)
    |> Repo.insert()
  end

  def update_feed(feed, attrs) do
    feed
    |> Feed.changeset(attrs)
    |> Repo.update()
  end
end
