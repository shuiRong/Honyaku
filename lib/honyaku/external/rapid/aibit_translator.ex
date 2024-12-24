defmodule Honyaku.External.Rapid.AiBitTranslator do
  @moduledoc """
  封装 AiBit Translator API 的调用
  """

  require Logger

  @base_url "https://aibit-translator.p.rapidapi.com/api/v1"

  @doc """
  翻译HTML文本的安全接口。如果翻译过程中出现错误, 会返回传入的默认值而不是抛出异常。
  """
  def translate(html, target_lang, source_lang) do
    headers = [
      {"x-rapidapi-host", "aibit-translator.p.rapidapi.com"},
      {"x-rapidapi-key", Application.fetch_env!(:honyaku, :rapid_api_key)}
    ]

    body = %{
      "from" => source_lang,
      "to" => target_lang,
      "html" => html
    }

    case Req.post("#{@base_url}/translator/html", headers: headers, json: body) do
      {:ok, %Req.Response{status: 200, body: %{"trans" => translated_html}}} ->
        {:ok, translated_html}

      {:ok, %Req.Response{status: 429}} ->
        {:error, :quota_exhausted}

      {:ok, reason} ->
        Logger.error("AiBit Translator API调用失败，未知错误：#{inspect(reason)}")
        {:error, :unknown_error}

      {:error, reason} ->
        Logger.error("AiBit Translator API调用失败：#{inspect(reason)}")
        {:error, reason}
    end
  end
end
