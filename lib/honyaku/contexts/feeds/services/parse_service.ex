defmodule Honyaku.Feeds.Services.ParseService do
  @moduledoc """
  解析、转换、翻译 RSS 订阅源
  """

  require Logger

  alias Honyaku.Feeds.Queries.Translation
  alias Honyaku.Job.TranslateJob
  alias Honyaku.External.Translate

  # 默认配置
  @defaults %{
    # 最大并发翻译数
    max_concurrency: 3,
    # 每批处理文章数
    chunk_size: 5,
    # 单个翻译超时时间
    timeout: :timer.minutes(2),
    # 重试次数
    retry_count: 3,
    # 重试延迟(ms)
    retry_delay: 1000
  }

  def to_feed(raw_content) do
    with {:ok, feed_type} <- detect_feed_type(raw_content),
         {:ok, parsed_feed} <- parse_feed(feed_type, raw_content) do
      {:ok, parsed_feed}
    end
  end

  def detect_feed_type(raw_content) do
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

  def parse_feed(:rss, raw_content) do
    with {:ok, rss_feed} <- FastRSS.parse_rss(raw_content) do
      File.write("tmp/rss_feed.json", Jason.encode!(rss_feed))
      {:ok, rss_to_atom(rss_feed)}
    end
  end

  def parse_feed(:atom, raw_content) do
    {:ok, feed} = FastRSS.parse_atom(raw_content)
    File.write("tmp/atom_feed.json", Jason.encode!(feed))
    {:ok, feed}
  end

  defp rss_to_atom(rss_feed) do
    %{
      "authors" => [],
      "base" => nil,
      "categories" => rss_feed["categories"],
      "contributors" => [],
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
      "subtitle" => %{
        "base" => nil,
        "lang" => nil,
        "type" => "Text",
        "value" => rss_feed["description"]
      },
      "title" => %{
        "base" => nil,
        "lang" => nil,
        "type" => "Text",
        "value" => rss_feed["title"]
      },
      "updated" => rss_feed["last_build_date"],
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
              "value" => item["content"]
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
            "rights" => nil,
            "source" => nil,
            "summary" => %{
              "base" => nil,
              "lang" => nil,
              "type" => "Text",
              "value" => item["description"]
            },
            "title" => %{
              "base" => nil,
              "lang" => nil,
              "type" => "Text",
              "value" => item["title"]
            },
            "published" => item["pub_date"],
            "updated" => item["pub_date"]
          }
        end)
    }
  end

  @doc """
  翻译 Feed，但首先查询数据库中是否已存在翻译结果，如果存在直接使用。
  """
  def translate_feed(saved_feed, saved_articles_tuple_list, target_lang, source_lang) do
    feed_with_preload =
      preload_feed_and_articles_with_translations(saved_feed, saved_articles_tuple_list)

    # 获取标题和副标题的翻译
    translated_title =
      get_field_translation(feed_with_preload, "title", target_lang) ||
        translate_or_schedule(saved_feed, "title", target_lang, source_lang)

    translated_subtitle =
      get_field_translation(feed_with_preload, "subtitle", target_lang) ||
        translate_or_schedule(saved_feed, "subtitle", target_lang, source_lang)

    # 翻译文章...
    translated_articles =
      feed_with_preload.articles
      |> translate_articles(target_lang, source_lang)

    %{
      saved_feed
      | title: translated_title,
        subtitle: translated_subtitle,
        articles: translated_articles
    }
  end

  # 从预加载的翻译中获取指定字段的翻译
  defp get_field_translation(feed_with_preload, field, target_lang) do
    feed_with_preload.translations
    |> Enum.find(&(&1.target_field == field && &1.target_language == target_lang))
    |> case do
      nil -> nil
      translation -> translation.translated_text
    end
  end

  # 尝试翻译，失败则创建后台任务并返回原文
  defp translate_or_schedule(feed, field, target_lang, source_lang) do
    original_text = Map.get(feed, field)

    case Translate.translate(original_text, target_lang, source_lang) do
      {:ok, translated_text} ->
        # 保存翻译结果
        Translation.insert_translation(%{
          target_field: field,
          target_language: target_lang,
          translated_text: translated_text,
          feed_id: feed.id
        })

        translated_text

      {:error, _reason} ->
        # 创建后台任务
        %{
          "saved_feed" => %{
            "id" => feed.id,
            "title" => feed.title,
            "subtitle" => feed.subtitle
          },
          "field" => field,
          "target_lang" => target_lang,
          "source_lang" => source_lang
        }
        |> new_translation_job()

        original_text
    end
  end

  defp preload_feed_and_articles_with_translations(saved_feed, saved_articles_tuple_list) do
    article_ids =
      saved_articles_tuple_list
      |> Enum.map(fn
        {:ok, article} ->
          article.id

        {:error, reason} ->
          Logger.error("解析文章失败: #{inspect(reason)}")
          nil
      end)
      |> Enum.reject(&is_nil/1)

    Translation.preload_feed_and_articles_with_translations(saved_feed, article_ids)
  end

  @doc """
  并行处理多篇文章的翻译，带流量控制
  """
  def translate_articles(preloaded_articles, target_lang, source_lang, opts \\ []) do
    config = Map.merge(@defaults, Map.new(opts))

    preloaded_articles
    |> Enum.chunk_every(config.chunk_size)
    |> Task.async_stream(
      &process_article_chunk(&1, target_lang, source_lang, config),
      max_concurrency: config.max_concurrency,
      timeout: config.timeout,
      on_timeout: :kill_task
    )
    |> Enum.reduce([], fn
      {:ok, results}, acc ->
        acc ++ results

      {:error, reason}, acc ->
        Logger.error("文章批次处理失败: #{inspect(reason)}")
        acc

      {:exit, reason}, acc ->
        Logger.error("文章批次处理退出: #{inspect(reason)}")
        acc
    end)
  end

  defp process_article_chunk(articles, target_lang, source_lang, config) do
    articles
    |> Task.async_stream(
      &translate_single_article(&1, target_lang, source_lang),
      # 每个批次串行处理，避免对翻译服务造成过大压力
      max_concurrency: 1,
      timeout: config.timeout,
      on_timeout: :kill_task
    )
    |> Enum.map(fn
      {:ok, result} ->
        result

      {:error, reason} ->
        Logger.error("文章处理失败: #{inspect(reason)}")
        nil

      {:exit, reason} ->
        Logger.error("文章处理退出: #{inspect(reason)}")
        nil
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp translate_single_article(article, target_lang, source_lang) do
    # 需要翻译的字段
    fields = [
      {:title, article.title},
      {:content, article.content.value},
      {:summary, article.summary.value}
    ]

    # 获取已有翻译
    existing_translations = get_existing_translations(article, target_lang)

    # 找出需要翻译的字段
    fields_to_translate =
      fields
      |> Enum.reject(fn {field, _} ->
        Map.has_key?(existing_translations, field)
      end)

    # 处理未翻译的字段
    new_translations =
      fields_to_translate
      |> Enum.map(fn {field, text} ->
        case Translate.translate(text, target_lang, source_lang) do
          {:ok, translated_text} ->
            # 保存成功的翻译
            Translation.insert_translation(%{
              target_field: Atom.to_string(field),
              target_language: target_lang,
              translated_text: translated_text,
              article_id: article.id
            })

            {field, translated_text}

          {:error, _reason} ->
            # 创建后台翻译任务
            %{
              "saved_article" => %{
                "id" => article.id,
                "title" => article.title,
                "content" => %{"value" => article.content.value},
                "summary" => %{"value" => article.summary.value}
              },
              "field" => field,
              "target_lang" => target_lang,
              "source_lang" => source_lang
            }
            |> new_translation_job()

            # 使用原文作为回退
            {field, text}
        end
      end)
      |> Enum.into(%{})

    # 合并已有翻译和新翻译
    translations = Map.merge(existing_translations, new_translations)

    # 构建翻译后的文章
    build_translated_article(article, translations)
  end

  defp get_existing_translations(article, target_lang) do
    article.translations
    |> Enum.filter(&(&1.target_language == target_lang))
    |> Enum.map(fn translation ->
      {String.to_atom(translation.target_field), translation.translated_text}
    end)
    |> Enum.into(%{})
  end

  defp build_translated_article(article, translations) do
    %{
      article
      | title: translations[:title] || article.title,
        content: %{
          value: translations[:content] || article.content.value,
          type: article.content.type
        },
        summary: %{
          value: translations[:summary] || article.summary.value,
          type: article.summary.type
        }
    }
  end

  defp new_translation_job(args) do
    args
    |> TranslateJob.new()
    |> Oban.insert()
  end
end
