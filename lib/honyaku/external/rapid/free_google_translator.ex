defmodule Honyaku.External.Rapid.FreeGoogleTranslator do
  @moduledoc """
  封装 Rapid 上的一些翻译 API 的调用
  """

  require Logger

  @base_url "https://free-google-translator.p.rapidapi.com/external-api"

  @doc """
  翻译文本的安全接口。如果翻译过程中出现错误,会返回传入的默认值而不是抛出异常。
  """
  def translate(text, target_lang, source_lang) do
    headers = [
      {"x-rapidapi-key", "#{Application.fetch_env!(:honyaku, :rapid_api_key)}"},
      {"x-rapidapi-host", "free-google-translator.p.rapidapi.com"}
    ]

    body = %{
      "translate" => "rapidapi",
      "from" => source_lang,
      "to" => target_lang,
      "query" => text
    }

    case Req.post("#{@base_url}/free-google-translator", headers: headers, json: body) do
      {:ok, %Req.Response{status: 200, body: %{"translation" => translated_text}}} ->
        Logger.info("翻译成功：#{translated_text}")
        {:ok, translated_text}

      {:ok, %Req.Response{status: 200, body: %{"message" => reason}}} ->
        Logger.info("翻译失败，接口返回错误信息：#{reason}")
        {:error, reason}

      {:ok, %Req.Response{status: 429}} ->
        {:error, :quota_exhausted}

      {:ok, reason} ->
        Logger.error("翻译失败，未知错误：#{inspect(reason)}")
        {:error, :unknown_error}

      {:error, reason} ->
        Logger.error("Free Google Translator API调用失败：#{inspect(reason)}")
        {:error, reason}
    end
  end
end
