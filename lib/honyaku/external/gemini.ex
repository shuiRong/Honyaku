defmodule Honyaku.External.Gemini do
  @moduledoc """
  封装 Gemini API 的调用
  """

  require Logger

  @base_url "https://generativelanguage.googleapis.com/v1beta"

  def translate(text, source_lang, target_lang) do
    Logger.info("开始翻译: #{text}")

    case Req.post(
           "#{@base_url}/models/gemini-1.5-flash-latest:generateContent?key=#{Application.fetch_env!(:honyaku, :gemini_api_key)}",
           json: %{
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
         ) do
      {:ok,
       %Req.Response{
         status: 200,
         body: %{
           "candidates" => [%{"content" => %{"parts" => [%{"text" => text}]}}]
         }
       }} ->
        {:ok, text}

      {:ok, %Req.Response{status: 429}} ->
        {:error, :quota_exhausted}

      {:ok, reason} ->
        Logger.error("翻译失败：#{inspect(reason)}")
        {:error, :unknown_error}

      {:error, reason} ->
        Logger.error("Gemini API调用失败：#{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  翻译文本的安全接口。如果翻译过程中出现错误,会返回传入的默认值而不是抛出异常。
  """
  def translate(text, source_lang, target_lang, default_text) do
    case translate(text, source_lang, target_lang) do
      {:ok, result} -> result
      {:error, _} -> default_text
    end
  end
end
