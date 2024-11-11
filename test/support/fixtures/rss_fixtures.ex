defmodule Honyaku.RSSFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Honyaku.RSS` context.
  """

  @doc """
  Generate a feed.
  """
  def feed_fixture(attrs \\ %{}) do
    {:ok, feed} =
      attrs
      |> Enum.into(%{
        source_lang: "some source_lang",
        target_lang: "some target_lang",
        url: "some url"
      })
      |> Honyaku.RSS.create_feed()

    feed
  end
end
