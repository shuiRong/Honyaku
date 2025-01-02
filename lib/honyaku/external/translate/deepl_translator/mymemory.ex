defmodule Honyaku.External.Translate.DeeplTranslator.MyMemory do
  require Logger

  @base_url "https://deep-translator-api.azurewebsites.net/"

  def translate(text, target_lang, source_lang) do
    body = %{
      "source" => source_lang,
      "target" => target_lang,
      "text" => text
    }

    case Req.post(
           "#{@base_url}/mymemory/",
           json: body
         ) do
      {:ok,
       %Req.Response{
         status: 200,
         body: %{"translation" => translated_text}
       }} ->
        {:ok, translated_text}

      {:ok, %Req.Response{status: 429}} ->
        {:error, :quota_exhausted}

      {:ok, reason} ->
        Logger.debug("MyMemory Translator API调用失败，未知错误：#{inspect(reason)}")
        {:error, :unknown_error}

      {:error, reason} ->
        Logger.debug("MyMemory Translator API调用失败：#{inspect(reason)}")
        {:error, reason}
    end
  end
end
