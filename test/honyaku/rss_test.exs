defmodule Honyaku.RSSTest do
  use Honyaku.DataCase

  alias Honyaku.RSS

  describe "feeds" do
    alias Honyaku.RSS.Feed

    import Honyaku.RSSFixtures

    @invalid_attrs %{url: nil, source_lang: nil, target_lang: nil}

    test "list_feeds/0 returns all feeds" do
      feed = feed_fixture()
      assert RSS.list_feeds() == [feed]
    end

    test "get_feed!/1 returns the feed with given id" do
      feed = feed_fixture()
      assert RSS.get_feed!(feed.id) == feed
    end

    test "create_feed/1 with valid data creates a feed" do
      valid_attrs = %{url: "some url", source_lang: "some source_lang", target_lang: "some target_lang"}

      assert {:ok, %Feed{} = feed} = RSS.create_feed(valid_attrs)
      assert feed.url == "some url"
      assert feed.source_lang == "some source_lang"
      assert feed.target_lang == "some target_lang"
    end

    test "create_feed/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = RSS.create_feed(@invalid_attrs)
    end

    test "update_feed/2 with valid data updates the feed" do
      feed = feed_fixture()
      update_attrs = %{url: "some updated url", source_lang: "some updated source_lang", target_lang: "some updated target_lang"}

      assert {:ok, %Feed{} = feed} = RSS.update_feed(feed, update_attrs)
      assert feed.url == "some updated url"
      assert feed.source_lang == "some updated source_lang"
      assert feed.target_lang == "some updated target_lang"
    end

    test "update_feed/2 with invalid data returns error changeset" do
      feed = feed_fixture()
      assert {:error, %Ecto.Changeset{}} = RSS.update_feed(feed, @invalid_attrs)
      assert feed == RSS.get_feed!(feed.id)
    end

    test "delete_feed/1 deletes the feed" do
      feed = feed_fixture()
      assert {:ok, %Feed{}} = RSS.delete_feed(feed)
      assert_raise Ecto.NoResultsError, fn -> RSS.get_feed!(feed.id) end
    end

    test "change_feed/1 returns a feed changeset" do
      feed = feed_fixture()
      assert %Ecto.Changeset{} = RSS.change_feed(feed)
    end
  end
end
