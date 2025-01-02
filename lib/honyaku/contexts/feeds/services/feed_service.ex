defmodule Honyaku.Feeds.Services.FeedService do
  @moduledoc """
  处理 RSS 订阅源的获取、解析和翻译
  """
  require Logger

  alias Honyaku.Feeds.Queries.{Feed, Article}
  alias Honyaku.Feeds.Services.ParseService
  alias Honyaku.Utils.DateTimeUtils

  def load_translated_feed(url, raw_content, target_lang, source_lang) do
    with {:ok, parsed_feed} <- ParseService.to_feed(raw_content),
         {:ok, saved_feed} <- save_feed(url, parsed_feed),
         {:ok, saved_articles_tuple_list} <- save_articles(saved_feed, parsed_feed["entries"]) do
      translated_feed =
        ParseService.translate_feed(
          saved_feed,
          saved_articles_tuple_list,
          target_lang,
          source_lang
        )

      {:ok, translated_feed}
    end
  end

  def save_feed(url, parsed_feed) do
    with {:ok, datetime} <- DateTimeUtils.parse_datetime(parsed_feed["updated"]) do
      # 先尝试查找已存在的 feed
      case Feed.get_feed_by_url(url) do
        nil ->
          Feed.insert_feed(%{
            url: url,
            title: parsed_feed["title"]["value"],
            subtitle: parsed_feed["subtitle"]["value"],
            original_updated_at: datetime
          })

        existing_feed ->
          # feed 已存在时更新信息
          existing_feed
          |> Feed.update_feed(%{
            title: parsed_feed["title"]["value"],
            subtitle: parsed_feed["subtitle"]["value"],
            original_updated_at: datetime
          })
      end
    end
  end

  @doc """
  保存RSS下的所有文章

  P.S. 这里返回的是一个 ok/error 的元组列表。
  """
  def save_articles(feed, entries) do
    saved_articles_tuple_list =
      entries
      |> Enum.map(fn entry ->
        # 这里解析时间会出错，导致该文章数据没有插入到数据库中
        # 导致出来的条目缺失
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

    {:ok, saved_articles_tuple_list}
  end

  def upsert_article(article) do
    case Article.get_article(article.link, article.feed_id) do
      nil ->
        Article.insert_article(article)

      # 先不考虑文章内容有变更，需要更新的情况。
      # 因为涉及到对应的translation也要更新，比较复杂。
      existing_article ->
        {:ok, existing_article}
    end
  end
end
