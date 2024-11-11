defmodule HonyakuWeb.FeedJSON do
  alias Honyaku.RSS.Feed

  @doc """
  Renders a list of feeds.
  """
  def index(%{feeds: feeds}) do
    %{data: for(feed <- feeds, do: data(feed))}
  end

  @doc """
  Renders a single feed.
  """
  def show(%{feed: feed}) do
    %{data: data(feed)}
  end

  defp data(%Feed{} = feed) do
    %{
      id: feed.id,
      url: feed.url,
      source_lang: feed.source_lang,
      target_lang: feed.target_lang
    }
  end
end
