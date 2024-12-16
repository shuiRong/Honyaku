defmodule HonyakuWeb.FeedController do
  use HonyakuWeb, :controller
  require Logger

  alias Honyaku.Feeds, as: FeedContext
  alias Honyaku.Feeds.BuildFeed
  action_fallback HonyakuWeb.FallbackController

  def index(conn, %{"url" => url, "target_lang" => target_lang, "source_lang" => source_lang}) do
    Logger.info("解析 RSS 订阅源: #{url}")

    case FeedContext.load_translated_feed(url, target_lang, source_lang) do
      {:ok, translated_feed} ->
        xml_content = translated_feed |> BuildFeed.build_feed()

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
end
