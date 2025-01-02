defmodule HonyakuWeb.FeedController do
  use HonyakuWeb, :controller
  require Logger

  alias Honyaku.Feeds
  action_fallback HonyakuWeb.FallbackController

  def index(conn, %{"url" => url, "target_lang" => target_lang, "source_lang" => source_lang}) do
    with {:ok, raw_content} <- fetch_feed_content(url),
         {:ok, translated_feed} <-
           Feeds.load_translated_feed(url, raw_content, target_lang, source_lang) do
      xml_content = Feeds.build_feed(translated_feed)

      conn
      |> put_resp_content_type("application/xml")
      |> text(xml_content)
    end
  end

  defp fetch_feed_content(url) do
    req =
      Req.new(max_redirects: 5)

    case Req.get(req, url: url) do
      {:ok, %Req.Response{status: 200, body: body}} -> {:ok, body}
      {:ok, reason} -> {:error, reason}
      {:error, reason} -> {:error, reason}
    end
  end
end
