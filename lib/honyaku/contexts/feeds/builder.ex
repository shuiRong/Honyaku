defmodule Honyaku.Feeds.BuildFeed do
  @moduledoc """
  构建 RSS 订阅源
  """

  require Logger
  alias Honyaku.Feeds.{Feed, Article}

  def build_feed(%Feed{
        title: title,
        subtitle: subtitle,
        id: id,
        url: url,
        original_updated_at: original_updated_at,
        articles: articles
      }) do
    Atomex.Feed.new(
      id,
      original_updated_at,
      title
    )
    |> then(fn feed ->
      # 如果 subtitle 为 nil，则不设置 subtitle
      case subtitle do
        nil ->
          feed

        _ ->
          feed |> Atomex.Feed.subtitle(subtitle)
      end
    end)
    |> Atomex.Feed.link(url)
    |> Atomex.Feed.entries(Enum.map(articles, &get_entry(&1)))
    |> Atomex.Feed.build()
    |> Atomex.generate_document()
  end

  defp get_entry(%Article{
         id: id,
         original_published_at: original_published_at,
         original_updated_at: original_updated_at,
         title: title,
         content: content,
         summary: summary,
         link: link
       }) do
    Atomex.Entry.new(
      id,
      original_updated_at,
      title
    )
    |> build_content(content.value, content.type)
    |> build_summary(summary.value, summary.type)
    |> Atomex.Entry.published(original_published_at)
    |> Atomex.Entry.link(link)
    |> Atomex.Entry.build()
  end

  defp build_content(entry, nil, _type) do
    entry
  end

  defp build_content(entry, value, type) do
    entry
    |> Atomex.Entry.content(value, type: type)
  end

  defp build_summary(entry, nil, _type) do
    entry
  end

  defp build_summary(entry, value, type) do
    entry
    |> Atomex.Entry.summary(value, type)
  end
end
