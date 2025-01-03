defmodule Honyaku.External.Translate.OpenRouter.Gemini2_Flash do
  require Logger

  @base_url "https://openrouter.ai/api/v1"

  def translate(text, target_lang, source_lang) do
    key = Application.fetch_env!(:honyaku, :open_router_api_key)

    headers = [
      {"Authorization", "Bearer #{key}"}
    ]

    body = %{
      "messages" => [
        %{
          "role" => "user",
          "content" => """
          Translate the following text from #{source_lang} to #{target_lang}, and return the translated text only:

          #{text}
          """
        }
      ],
      "model" => "google/gemini-2.0-flash-thinking-exp:free",
      "temperature" => 1,
      "stream" => false
    }

    case Req.post(
           "#{@base_url}/chat/completions",
           headers: headers,
           json: body
         ) do
      {:ok,
       %Req.Response{
         status: 200,
         body: %{"choices" => [%{"message" => %{"content" => content}}]}
       }} ->
        {:ok, content}

      {:ok,
       %Req.Response{
         status: 200,
         body: %{"error" => %{"code" => 429}}
       }} ->
        {:error, :quota_exhausted}

      {:ok, %Req.Response{status: 429}} ->
        {:error, :quota_exhausted}

      {:ok, reason} ->
        Logger.debug("Gemini 2 Flash Translator API调用失败，未知错误：#{inspect(reason)}")
        {:error, :unknown_error}

      {:error, reason} ->
        Logger.debug("Gemini 2 Flash Translator API调用失败：#{inspect(reason)}")
        {:error, reason}
    end
  end
end
