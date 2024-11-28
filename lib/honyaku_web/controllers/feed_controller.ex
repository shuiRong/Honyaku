defmodule HonyakuWeb.FeedController do
  use HonyakuWeb, :controller
  require Logger

  alias Honyaku.RSS
  alias Honyaku.RSS.Feed
  alias Honyaku.Feeds.RSSTranslator
  # alias HonyakuWeb.FeedXML
  action_fallback HonyakuWeb.FallbackController

  def index(conn, %{"url" => url, "source_lang" => source_lang, "target_lang" => target_lang}) do
    case RSSTranslator.translate_feed(url, source_lang, target_lang) do
      {:ok, translated_feed, feed_type} ->
        xml_content = translated_feed |> build_feed(feed_type)

        conn
        |> put_resp_content_type("application/xml")
        |> text(xml_content)

      {:error, reason} ->
        Logger.error("解析失败: #{inspect(reason)}")

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: reason})
    end
  end

  def build_feed(translated_feed, :rss) do
    link = translated_feed["link"]

    last_build_date =
      translated_feed["last_build_date"]
      |> Timex.parse!("{RFC1123}")

    Atomex.Feed.new(link, last_build_date, translated_feed["title"])
    |> Atomex.Feed.add_field(:description, nil, translated_feed["description"])
    |> Atomex.Feed.add_field(:language, nil, translated_feed["language"])
    |> Atomex.Feed.add_field(:copyright, nil, translated_feed["copyright"])
    |> Atomex.Feed.link(link)
    |> Atomex.Feed.entries(Enum.map(translated_feed["items"], &get_entry(&1, :rss)))
    |> Atomex.Feed.build()
    |> Atomex.generate_document()
  end

  def build_feed(translated_feed, :atom) do
    title = translated_feed["title"]["value"]
    id = translated_feed["id"]

    Logger.info("link: #{inspect(translated_feed["links"])}")

    Atomex.Feed.new(
      id,
      DateTime.utc_now(),
      title
    )
    |> then(fn feed ->
      Enum.reduce(translated_feed["links"], feed, fn link, acc ->
        acc
        |> Atomex.Feed.link(
          link["href"],
          rel: link["rel"],
          type: link["mime_type"],
          hreflang: link["hreflang"],
          title: link["title"],
          length: link["length"]
        )
      end)
    end)
    |> Atomex.Feed.entries(Enum.map(translated_feed["entries"], &get_entry(&1, :atom)))
    |> Atomex.Feed.build()
    |> Atomex.generate_document()
  end

  defp get_entry(
         %{
           "link" => link,
           "pub_date" => pub_date,
           "title" => title,
           "description" => description
         },
         :rss
       ) do
    # 将 RFC 时间字符串解析为 DateTime 支持的格式
    datetime =
      pub_date
      |> Timex.parse!("{RFC1123}")

    Atomex.Entry.new(
      link,
      datetime,
      title
    )
    |> Atomex.Entry.link(link)
    |> Atomex.Entry.summary(description, "html")
    |> Atomex.Entry.build()
  end

  defp get_entry(
         %{
           "id" => id,
           "published" => published,
           "title" => %{"value" => title},
           "content" => %{
             "value" => content,
             "content_type" => type,
             "base" => base,
             "lang" => lang,
             "src" => src
           },
           "links" => links
         },
         :atom
       ) do
    # 将 RFC 时间字符串解析为 DateTime 支持的格式
    datetime =
      published
      |> Timex.parse!("{ISO:Extended}")

    Atomex.Entry.new(
      id,
      datetime,
      title
    )
    |> Atomex.Entry.content(content, type: type, base: base, lang: lang, src: src)
    |> then(fn entry ->
      Enum.reduce(links, entry, fn link, acc ->
        acc
        |> Atomex.Entry.link(
          link["href"],
          rel: link["rel"],
          type: link["mime_type"],
          hreflang: link["hreflang"],
          title: link["title"],
          length: link["length"]
        )
      end)
    end)
    |> Atomex.Entry.build()
  end

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
