defmodule Honyaku.Feeds.Services.BuildService do
  @moduledoc """
  构建 RSS 订阅源
  """

  require Logger
  alias Honyaku.Feeds.{Feed, Article}

  def build_feed(%Feed{} = feed) do
    Atomex.Feed.new(
      feed.id,
      feed.original_updated_at,
      feed.title || "Untitled Feed"
    )
    |> then(fn atomex_feed ->
      # 如果 subtitle 为 nil，则不设置 subtitle
      case feed.subtitle do
        nil ->
          atomex_feed

        _ ->
          atomex_feed |> Atomex.Feed.subtitle(feed.subtitle)
      end
    end)
    |> Atomex.Feed.link(feed.url)
    |> Atomex.Feed.entries(Enum.map(feed.articles, &get_entry(&1)))
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
