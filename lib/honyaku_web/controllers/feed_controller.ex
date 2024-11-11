defmodule HonyakuWeb.FeedController do
  use HonyakuWeb, :controller

  alias Honyaku.RSS
  alias Honyaku.RSS.Feed

  action_fallback HonyakuWeb.FallbackController

  def index(conn, _params) do
    feeds = RSS.list_feeds()
    render(conn, :index, feeds: feeds)
  end

  def create(conn, %{"feed" => feed_params}) do
    with {:ok, %Feed{} = feed} <- RSS.create_feed(feed_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/feeds/#{feed}")
      |> render(:show, feed: feed)
    end
  end

  def show(conn, %{"id" => id}) do
    feed = RSS.get_feed!(id)
    render(conn, :show, feed: feed)
  end

  def update(conn, %{"id" => id, "feed" => feed_params}) do
    feed = RSS.get_feed!(id)

    with {:ok, %Feed{} = feed} <- RSS.update_feed(feed, feed_params) do
      render(conn, :show, feed: feed)
    end
  end

  def delete(conn, %{"id" => id}) do
    feed = RSS.get_feed!(id)

    with {:ok, %Feed{}} <- RSS.delete_feed(feed) do
      send_resp(conn, :no_content, "")
    end
  end
end
