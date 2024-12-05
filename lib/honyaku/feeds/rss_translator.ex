defmodule Honyaku.Feeds.RSSTranslator do
  @moduledoc """
  处理 RSS 订阅源的获取、解析和翻译
  """
  require Logger

  # alias Honyaku.External.Gemini
  alias Honyaku.External.DeepL

  def load_translated_feed(url, source_lang, target_lang) do
    with {:ok, parsed_feed} <- load_feed(url),
         {:ok, translated_feed} <- translate_feed(parsed_feed, source_lang, target_lang) do
      {:ok, translated_feed}
    end
  end

  def load_feed(url) do
    with {:ok, raw_content} <- fetch_feed_content(url),
         {:ok, feed_type} <- detect_feed_type(raw_content),
         {:ok, parsed_feed} <- parse_feed(feed_type, raw_content) do
      {:ok, parsed_feed}
    end
  end

  defp fetch_feed_content(url) do
    req =
      Req.new(
        headers: [{"user-agent", "RSS Translator Bot"}],
        max_redirects: 5
      )

    case Req.get(req, url: url) do
      {:ok, %Req.Response{status: 200, body: body}} -> {:ok, body}
      {:ok, reason} -> {:error, reason}
      {:error, reason} -> {:error, reason}
    end
  end

  defp detect_feed_type(raw_content) do
    trimmed_content = String.trim_leading(raw_content)

    cond do
      String.starts_with?(trimmed_content, "<?xml") ->
        case String.contains?(trimmed_content, "<rss") do
          true ->
            {:ok, :rss}

          false ->
            case String.contains?(trimmed_content, "<feed") do
              true -> {:ok, :atom}
              false -> {:error, "未知的 feed 类型"}
            end
        end

      String.starts_with?(trimmed_content, "<rss") ->
        {:ok, :rss}

      String.starts_with?(trimmed_content, "<feed") ->
        {:ok, :atom}

      true ->
        {:error, "未知的 feed 类型"}
    end
  end

  defp parse_feed(:rss, raw_content) do
    case FastRSS.parse_rss(raw_content) do
      {:ok, rss_feed} -> {:ok, rss_to_atom(rss_feed)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse_feed(:atom, raw_content) do
    FastRSS.parse_atom(raw_content)
  end

  defp rss_to_atom(rss_feed) do
    %{
      "authors" => [],
      "base" => nil,
      "categories" => rss_feed["categories"],
      "contributors" => [],
      "entries" =>
        Enum.map(rss_feed["items"], fn item ->
          %{
            "authors" => [
              %{
                "email" => nil,
                "name" => item["author"],
                "uri" => nil
              }
            ],
            "categories" => item["categories"],
            "content" => %{
              "base" => nil,
              "content_type" => "html",
              "lang" => nil,
              "src" => nil,
              "value" => item["description"]
            },
            "contributors" => [],
            "extensions" => %{},
            "id" => item["guid"]["value"],
            "links" => [
              %{
                "href" => item["link"],
                "hreflang" => nil,
                "length" => nil,
                "mime_type" => "text/html",
                "rel" => "alternate",
                "title" => nil
              }
            ],
            "published" => item["pub_date"] |> Timex.parse!("{RFC1123}"),
            "rights" => nil,
            "source" => nil,
            "summary" => nil,
            "title" => %{
              "base" => nil,
              "lang" => nil,
              "type" => "Text",
              "value" => item["title"]
            },
            "updated" => item["pub_date"]
          }
        end),
      "extensions" => %{},
      "generator" => rss_feed["generator"],
      "icon" => nil,
      "id" => rss_feed["link"],
      "lang" => rss_feed["language"],
      "links" => [
        %{
          "href" => rss_feed["link"],
          "hreflang" => nil,
          "length" => nil,
          "mime_type" => "text/html",
          "rel" => "alternate",
          "title" => nil
        }
      ],
      "logo" => nil,
      "namespaces" => %{},
      "rights" => rss_feed["copyright"],
      "subtitle" => rss_feed["description"],
      "title" => %{
        "base" => nil,
        "lang" => nil,
        "type" => "Text",
        "value" => rss_feed["title"]
      },
      "updated" => rss_feed["last_build_date"]
    }
  end

  defp translate_feed(feed, source_lang, target_lang) do
    # 并行翻译标题和副标题
    feed_tasks = [
      Task.async(fn ->
        translate(feed["title"]["value"], source_lang, target_lang)
      end),
      Task.async(fn ->
        translate(feed["subtitle"], source_lang, target_lang)
      end)
    ]

    # 并行翻译所有条目
    entry_tasks =
      feed["entries"]
      |> Enum.map(fn entry ->
        Task.async(fn ->
          title =
            translate(
              entry["title"]["value"],
              source_lang,
              target_lang
            )

          content =
            translate(
              entry["content"]["value"],
              source_lang,
              target_lang
            )

          %{
            entry
            | "title" => entry["title"] |> Map.put("value", title),
              "content" => entry["content"] |> Map.put("value", content)
          }
        end)
      end)

    # 等待所有任务完成
    [title, subtitle] = Task.await_many(feed_tasks)
    entries = Task.await_many(entry_tasks)

    {:ok,
     %{
       feed
       | "title" => %{
           feed["title"]
           | "value" => title
         },
         "subtitle" => subtitle,
         "entries" => entries
     }}
  end

  defp translate(text, source_lang, target_lang) do
    DeepL.translate(text, source_lang, target_lang)
  end
end
