defmodule HonyakuWeb.FeedController do
  use HonyakuWeb, :controller
  require Logger

  alias Honyaku.Feeds.RSSTranslator
  action_fallback HonyakuWeb.FallbackController

  def index(conn, %{"url" => url, "source_lang" => source_lang, "target_lang" => target_lang}) do
    case RSSTranslator.load_translated_feed(url, source_lang, target_lang) do
      {:ok, translated_feed} ->
        xml_content = translated_feed |> build_feed()

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

  def build_feed(translated_feed) do
    title = translated_feed["title"]["value"]
    id = translated_feed["id"]
    updated = translated_feed["updated"] |> Timex.parse!("{RFC1123}")

    Atomex.Feed.new(
      id,
      updated,
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
    |> Atomex.Feed.add_field(:subtitle, %{}, translated_feed["subtitle"])
    |> Atomex.Feed.entries(Enum.map(translated_feed["entries"], &get_entry(&1)))
    |> Atomex.Feed.build()
    |> Atomex.generate_document()
  end

  defp get_entry(%{
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
       }) do
    # 将 RFC 时间字符串解析为 DateTime 支持的格式
    datetime =
      published

    # |> Timex.parse!("{ISO:Extended}")

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
end
