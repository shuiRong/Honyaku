defmodule Honyaku.TranslateJob do
  use Oban.Worker, queue: :translate, unique: true

  require Logger

  alias Honyaku.Feeds.Parser

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "saved_feed" => %{
            "id" => id,
            "title" => title,
            "subtitle" => subtitle
          },
          "field" => field,
          "target_lang" => target_lang,
          "source_lang" => source_lang
        }
      }) do
    case Parser.translate_and_save_feed_field(
           %{
             id: id,
             title: title,
             subtitle: subtitle
           },
           field,
           target_lang,
           source_lang
         ) do
      {:ok, translated_text} ->
        Logger.info("Feed 翻译成功 - #{field}: #{inspect(translated_text)}")
        :ok

      error ->
        Logger.error("Feed 翻译失败 - #{field}: #{inspect(error)}")
        error
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "saved_article" => %{
            "id" => id,
            "title" => title,
            "content" => %{"value" => content},
            "summary" => %{"value" => summary}
          },
          "field" => field,
          "target_lang" => target_lang,
          "source_lang" => source_lang
        }
      }) do
    case Parser.translate_and_save_article_field(
           %{
             id: id,
             title: title,
             content: %{
               "value" => content
             },
             summary: %{
               "value" => summary
             }
           },
           field,
           target_lang,
           source_lang
         ) do
      {:ok, translated_text} ->
        Logger.info("Article 翻译成功 - #{field}: #{inspect(translated_text)}")
        :ok

      error ->
        Logger.error("Article 翻译失败 - #{field}: #{inspect(error)}")
        error
    end
  end
end
