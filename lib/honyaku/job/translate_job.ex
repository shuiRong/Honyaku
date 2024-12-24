defmodule Honyaku.TranslateJob do
  use Oban.Worker, queue: :translate, unique: true

  require Logger

  alias Honyaku.Feeds.Parser

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "saved_feed" => saved_feed,
          "field" => field,
          "target_lang" => target_lang,
          "source_lang" => source_lang
        }
      }) do
    Parser.translate_and_save_feed_field(saved_feed, field, target_lang, source_lang)

    :ok
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "saved_article" => saved_article,
          "field" => field,
          "target_lang" => target_lang,
          "source_lang" => source_lang
        }
      }) do
    Parser.translate_and_save_article_field(saved_article, field, target_lang, source_lang)

    :ok
  end
end
