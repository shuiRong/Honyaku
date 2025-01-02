defmodule Honyaku.External.Translate.Rapid.DeepLTranslator do
  require Logger

  @base_url "https://deepl-translator4.p.rapidapi.com/api/v1"

  def translate(text, target_lang, source_lang) do
    case Req.post(
           "#{@base_url}/translate",
           headers: [
             {"Authorization",
              "DeepL-Auth-Key #{Application.fetch_env!(:honyaku, :deepl_api_key)}"}
           ],
           json: %{
             "text" => [
               text
             ],
             "to" => target_lang,
             "from" => source_lang
           }
         ) do
      {:ok,
       %Req.Response{
         status: 200,
         body: %{
           "text" => text
         }
       }} ->
        {:ok, text}

      {:ok, %Req.Response{status: 429}} ->
        {:error, :quota_exhausted}

      {:ok, reason} ->
        Logger.debug("DeepL Translator API调用失败，未知错误：#{inspect(reason)}")
        {:error, :unknown_error}

      {:error, reason} ->
        Logger.debug("DeepL Translator API调用失败：#{inspect(reason)}")
        {:error, reason}
    end
  end
end
