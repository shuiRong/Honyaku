defmodule Honyaku.External.Groq.Gemma2_2b do
  require Logger

  @base_url "https://api.groq.com/openai/v1"

  def translate(text, target_lang, source_lang) do
    key = Application.fetch_env!(:honyaku, :groq_api_key)

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
      "model" => "gemma2-9b-it",
      "temperature" => 1,
      "max_tokens" => 8192,
      "top_p" => 1,
      "stream" => false,
      "stop" => nil
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

      {:ok, %Req.Response{status: 429}} ->
        {:error, :quota_exhausted}

      {:ok, reason} ->
        Logger.error("翻译失败，未知错误：#{inspect(reason)}")
        {:error, :unknown_error}

      {:error, reason} ->
        Logger.error("Gemini API调用失败：#{inspect(reason)}")
        {:error, reason}
    end
  end
end
