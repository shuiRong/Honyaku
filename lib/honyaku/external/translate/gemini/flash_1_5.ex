defmodule Honyaku.External.Translate.Gemini.Flash1_5 do
  @moduledoc """
  封装 Gemini API 的调用
  """

  require Logger

  @base_url "https://generativelanguage.googleapis.com/v1beta"

  def translate(text, target_lang, source_lang) do
    key = Application.fetch_env!(:honyaku, :gemini_api_key)

    body = %{
      "contents" => [
        %{
          "parts" => [
            %{
              "text" => """
              Translate the following text from #{source_lang} to #{target_lang}, and return the translated text only:

              #{text}
              """
            }
          ]
        }
      ]
    }

    case Req.post(
           "#{@base_url}/models/gemini-1.5-flash-latest:generateContent?key=#{key}",
           json: body
         ) do
      {:ok,
       %Req.Response{
         status: 200,
         body: %{"candidates" => [%{"content" => %{"parts" => [%{"text" => translated_text}]}}]}
       }} ->
        {:ok, translated_text}

      {:ok, %Req.Response{status: 429}} ->
        {:error, :quota_exhausted}

      {:ok, reason} ->
        Logger.debug("Gemini Flash 1.5 Translator API调用失败，未知错误：#{inspect(reason)}")
        {:error, :unknown_error}

      {:error, reason} ->
        Logger.debug("Gemini Flash 1.5 Translator API调用失败：#{inspect(reason)}")
        {:error, reason}
    end
  end
end
