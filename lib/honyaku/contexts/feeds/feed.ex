defmodule Honyaku.Feeds do
  @moduledoc """
  处理 RSS 订阅源的获取、解析和翻译
  """
  require Logger

  alias Honyaku.Repo
  alias Honyaku.Feeds.Feed
  alias Honyaku.Feeds.Article
  alias Honyaku.Feeds.Parser
  alias Honyaku.Utils.DateTimeUtils

  def load_translated_feed(url, target_lang, source_lang) do
    with {:ok, parsed_feed} <- load_feed(url),
         {:ok, feed, save_feed_and_articles} <- save_feed_and_articles(url, parsed_feed),
         {:ok, translated_feed} <-
           Parser.translate_feed(feed, save_feed_and_articles, target_lang, source_lang) do
      {:ok, translated_feed}
    end
  end

  def load_feed(url) do
    with {:ok, raw_content} <- fetch_feed_content(url),
         {:ok, feed_type} <- Parser.detect_feed_type(raw_content),
         {:ok, parsed_feed} <- Parser.parse_feed(feed_type, raw_content) do
      {:ok, parsed_feed}
    end
  end

  defp save_feed_and_articles(url, parsed_feed) do
    with {:ok, saved_feed} <- save_feed(url, parsed_feed),
         saved_articles_tuple_list <- save_articles(saved_feed, parsed_feed["entries"]) do
      {:ok, saved_feed, saved_articles_tuple_list}
    end
  end

  def save_feed(url, parsed_feed) do
    with {:ok, datetime} <- DateTimeUtils.parse_datetime(parsed_feed["updated"]) do
      # 先尝试查找已存在的 feed
      case Repo.get_by(Feed, url: url) do
        nil ->
          %Feed{}
          |> Feed.changeset(%{
            url: url,
            title: parsed_feed["title"]["value"],
            subtitle: parsed_feed["subtitle"]["value"],
            original_updated_at: datetime
          })
          |> Repo.insert()

        existing_feed ->
          # feed 已存在时更新信息
          existing_feed
          |> Feed.changeset(%{
            title: parsed_feed["title"]["value"],
            subtitle: parsed_feed["subtitle"]["value"],
            original_updated_at: datetime
          })
          |> Repo.update()
      end
    end
  end

  @doc """
  保存RSS下的所有文章

  P.S. 这里返回的是一个 ok/error 的元组列表。
  """
  def save_articles(feed, entries) do
    entries
    |> Enum.map(fn entry ->
      with {:ok, original_published_at} <-
             DateTimeUtils.parse_datetime(entry["published"] || entry["updated"]),
           {:ok, original_updated_at} <-
             DateTimeUtils.parse_datetime(entry["updated"] || entry["published"]) do
        article = %{
          feed_id: feed.id,
          link: entry["links"] |> List.first() |> Map.get("href"),
          title: entry["title"]["value"],
          language: entry["content"]["lang"],
          original_published_at: original_published_at,
          original_updated_at: original_updated_at,
          content: %{type: entry["content"]["content_type"], value: entry["content"]["value"]},
          summary: %{type: entry["summary"]["content_type"], value: entry["summary"]["value"]}
        }

        upsert_article(article)
      end
    end)
  end

  def upsert_article(article) do
    case Repo.get_by(Article, link: article.link, feed_id: article.feed_id) do
      nil ->
        %Article{}
        |> Article.changeset(article)
        |> Repo.insert()

      # 先不考虑文章内容有变更，需要更新的情况。
      # 因为涉及到对应的translation也要更新，比较复杂。
      existing_article ->
        {:ok, existing_article}
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
