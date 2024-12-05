defmodule Honyaku.External.DeepL do
  @moduledoc """
  封装 DeepL API 的调用
  """

  require Logger

  @base_url "https://api-free.deepl.com/v2"

  def translate(text, target_lang, _source_lang) do
    Logger.info("开始翻译: #{text}")

    case Req.post(
           "#{@base_url}/v2/translate",
           headers: [
             {"Authorization",
              "DeepL-Auth-Key #{Application.fetch_env!(:honyaku, :deepl_api_key)}"}
           ],
           json: %{
             "text" => [
               text
             ],
             "target_lang" => target_lang
           }
         ) do
      {:ok,
       %Req.Response{
         status: 200,
         body: %{
           "translations" => [%{"text" => text}]
         }
       }} ->
        {:ok, text}

      {:ok, %Req.Response{status: 429}} ->
        {:error, :quota_exhausted}

      {:ok, reason} ->
        Logger.error("翻译失败：#{inspect(reason)}")
        {:error, :unknown_error}

      {:error, reason} ->
        Logger.error("DeepL API调用失败：#{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  翻译文本的安全接口。如果翻译过程中出现错误,会返回传入的默认值而不是抛出异常。
  """
  def translate(text, target_lang, source_lang) do
    case translate(text, target_lang, source_lang) do
      {:ok, result} -> result
      {:error, _} -> text
    end
  end
end
