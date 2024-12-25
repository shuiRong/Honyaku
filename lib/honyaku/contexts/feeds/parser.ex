defmodule Honyaku.Feeds.Parser do
  @moduledoc """
  解析、转换、翻译 RSS 订阅源
  """

  require Logger
  import Ecto.Query

  alias Honyaku.External.TranslationBalancer
  alias Honyaku.Repo
  alias Honyaku.Feeds.{Article, Translation}

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

    # 创建标题和副标题的翻译任务
    title_task =
      get_feed_field_translation(feed_with_preload, saved_feed, "title", target_lang, source_lang)

    subtitle_task =
      get_feed_field_translation(
        feed_with_preload,
        saved_feed,
        "subtitle",
        target_lang,
        source_lang
      )

    # 创建所有条目的翻译任务
    article_articles =
      Enum.map(feed_with_preload.articles, fn article ->
        Task.async(fn ->
          # 为每个字段创建独立的翻译任务
          article_title_task =
            get_feed_article_field_translation(article, "title", target_lang, source_lang)

          article_content_task =
            get_feed_article_field_translation(article, "content", target_lang, source_lang)

          article_summary_task =
            get_feed_article_field_translation(article, "summary", target_lang, source_lang)

          tasks_with_results =
            Task.yield_many(
              [article_title_task, article_content_task, article_summary_task],
              timeout: 1_000 * 60,
              on_timeout: :kill_task
            )

          [title_result, content_result, summary_result] =
            Enum.map(tasks_with_results, fn
              {_task, {:ok, {:ok, translated_text}}} -> {:ok, translated_text}
              {_task, {:ok, {:error, reason}}} -> {:error, reason}
              {_task, {:exit, reason}} -> {:error, reason}
              {_task, nil} -> {:error, :timeout}
            end)

          # 处理标题翻译
          translated_title =
            case title_result do
              {:ok, text} ->
                text

              {:error, _reason} ->
                # 创建标题翻译任务
                %{
                  saved_article: %{
                    id: article.id,
                    title: article.title,
                    content: article.content,
                    summary: article.summary
                  },
                  field: "title",
                  target_lang: target_lang,
                  source_lang: source_lang
                }
                |> Honyaku.TranslateJob.new()
                |> Oban.insert()

                article.title
            end

          # 处理内容翻译
          translated_content =
            case content_result do
              {:ok, text} ->
                text

              {:error, _reason} ->
                # 创建内容翻译任务
                %{
                  saved_article: %{
                    id: article.id,
                    title: article.title,
                    content: article.content,
                    summary: article.summary
                  },
                  field: "content",
                  target_lang: target_lang,
                  source_lang: source_lang
                }
                |> Honyaku.TranslateJob.new()
                |> Oban.insert()

                article.content.value
            end

          # 处理摘要翻译
          translated_summary =
            case summary_result do
              {:ok, text} ->
                text

              {:error, _reason} ->
                # 创建摘要翻译任务
                %{
                  saved_article: %{
                    id: article.id,
                    title: article.title,
                    content: article.content,
                    summary: article.summary
                  },
                  field: "summary",
                  target_lang: target_lang,
                  source_lang: source_lang
                }
                |> Honyaku.TranslateJob.new()
                |> Oban.insert()

                article.summary.value
            end

          {:ok,
           %{
             article
             | title: translated_title,
               content: %{
                 value: translated_content,
                 type: article.content.type
               },
               summary: %{
                 value: translated_summary,
                 type: article.summary.type
               }
           }}
        end)
      end)

    # 等待标题和副标题的翻译任务完成
    translated_title =
      case Task.await(title_task, 1_000 * 60) do
        {:ok, text} ->
          text

        {:error, reason} ->
          Logger.debug("标题翻译失败：#{inspect(reason)}")

          # 创建翻译任务
          %{
            saved_feed: %{
              id: saved_feed.id,
              title: saved_feed.title,
              subtitle: saved_feed.subtitle
            },
            field: "title",
            target_lang: target_lang,
            source_lang: source_lang
          }
          |> Honyaku.TranslateJob.new()
          |> Oban.insert()

          # 使用原始标题作为回退
          saved_feed.title
      end

    translated_subtitle =
      case Task.await(subtitle_task, 1_000 * 60) do
        {:ok, text} ->
          text

        {:error, reason} ->
          Logger.error("副标题翻译失败：#{inspect(reason)}")

          # 创建翻译任务
          %{
            saved_feed: %{
              id: saved_feed.id,
              title: saved_feed.title,
              subtitle: saved_feed.subtitle
            },
            field: "subtitle",
            target_lang: target_lang,
            source_lang: source_lang
          }
          |> Honyaku.TranslateJob.new()
          |> Oban.insert()

          # 使用原始副标题作为兜底
          saved_feed.subtitle
      end

    # 等待所有条目的翻译任务完成
    translated_articles =
      article_articles
      |> Enum.map(fn task ->
        {:ok, article} = Task.await(task, 1_000 * 60)
        article
      end)

    {:ok,
     %{
       saved_feed
       | title: translated_title,
         subtitle: translated_subtitle,
         articles: translated_articles
     }}
  end

  # 获取 Feed 字段的翻译结果
  # 1. 如果数据库中已存在翻译结果，则直接返回
  # 2. 如果数据库中不存在翻译结果，则创建翻译任务
  # 2.1 如果翻译任务成功，则将翻译结果保存到数据库中
  defp get_feed_field_translation(feed_with_preload, saved_feed, field, target_lang, source_lang) do
    Task.async(fn ->
      case Enum.find(feed_with_preload.translations, fn t ->
             t.target_field == field and t.target_language == target_lang
           end) do
        %Translation{translated_text: translated_text} ->
          {:ok, translated_text}

        nil ->
          translate_and_save_feed_field(saved_feed, field, target_lang, source_lang)
      end
    end)
  end

  def translate_and_save_feed_field(saved_feed, field, target_lang, source_lang) do
    text =
      case field do
        "title" -> saved_feed.title
        "subtitle" -> saved_feed.subtitle
        _ -> ""
      end

    Logger.info("translate_and_save_feed_field: #{field} #{target_lang} #{source_lang}")

    with {:ok, translated_text} <- translate(text, target_lang, source_lang),
         {:ok, _translation} <-
           Repo.insert(%Translation{
             target_field: field,
             target_language: target_lang,
             translated_text: translated_text,
             feed_id: saved_feed.id
           }) do
      {:ok, translated_text}
    end
  end

  @doc """
  获取 Article 字段的翻译结果
  1. 如果数据库中已存在翻译结果，则直接返回
  2. 如果数据库中不存在翻译结果，则创建翻译任务
  2.1 如果翻译任务成功，则将翻译结果保存到数据库中
  """
  def get_feed_article_field_translation(saved_article, field, target_lang, source_lang) do
    Task.async(fn ->
      case Enum.find(saved_article.translations, fn t ->
             t.target_field == field and t.target_language == target_lang
           end) do
        %Translation{translated_text: translated_text} ->
          {:ok, translated_text}

        nil ->
          translate_and_save_article_field(saved_article, field, target_lang, source_lang)
      end
    end)
  end

  def translate_and_save_article_field(saved_article, field, target_lang, source_lang) do
    text =
      case field do
        "title" -> saved_article.title
        "content" -> saved_article.content.value
        "summary" -> saved_article.summary.value
        _ -> ""
      end

    Logger.info("translate_and_save_article_field: #{field} #{target_lang} #{source_lang}")

    with {:ok, translated_text} <- translate(text, target_lang, source_lang),
         {:ok, _translation} <-
           Repo.insert(%Translation{
             target_field: field,
             target_language: target_lang,
             translated_text: translated_text,
             article_id: saved_article.id
           }) do
      {:ok, translated_text}
    end
  end

  defp translate(nil, _target_lang, _source_lang) do
    {:error, :nil_text}
  end

  defp translate(text, target_lang, source_lang) do
    TranslationBalancer.translate(text, target_lang, source_lang)
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

    query_articles =
      from a in Article,
        where: a.id in ^article_ids,
        preload: [:translations],
        order_by: [desc: a.original_updated_at]

    saved_feed
    |> Repo.preload([
      :translations,
      articles: query_articles
    ])
  end
end
