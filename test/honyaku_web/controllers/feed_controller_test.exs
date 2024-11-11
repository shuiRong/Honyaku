defmodule HonyakuWeb.FeedControllerTest do
  use HonyakuWeb.ConnCase

  import Honyaku.RSSFixtures

  alias Honyaku.RSS.Feed

  @create_attrs %{
    url: "some url",
    source_lang: "some source_lang",
    target_lang: "some target_lang"
  }
  @update_attrs %{
    url: "some updated url",
    source_lang: "some updated source_lang",
    target_lang: "some updated target_lang"
  }
  @invalid_attrs %{url: nil, source_lang: nil, target_lang: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all feeds", %{conn: conn} do
      conn = get(conn, ~p"/api/feeds")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create feed" do
    test "renders feed when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/feeds", feed: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/feeds/#{id}")

      assert %{
               "id" => ^id,
               "source_lang" => "some source_lang",
               "target_lang" => "some target_lang",
               "url" => "some url"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/feeds", feed: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update feed" do
    setup [:create_feed]

    test "renders feed when data is valid", %{conn: conn, feed: %Feed{id: id} = feed} do
      conn = put(conn, ~p"/api/feeds/#{feed}", feed: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/feeds/#{id}")

      assert %{
               "id" => ^id,
               "source_lang" => "some updated source_lang",
               "target_lang" => "some updated target_lang",
               "url" => "some updated url"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, feed: feed} do
      conn = put(conn, ~p"/api/feeds/#{feed}", feed: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete feed" do
    setup [:create_feed]

    test "deletes chosen feed", %{conn: conn, feed: feed} do
      conn = delete(conn, ~p"/api/feeds/#{feed}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/feeds/#{feed}")
      end
    end
  end

  defp create_feed(_) do
    feed = feed_fixture()
    %{feed: feed}
  end
end
