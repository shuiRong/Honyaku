defmodule Honyaku.External.TranslationBalancer do
  @moduledoc """
  请求负载均衡器，支持洗牌算法。
  """

  require Logger

  alias Honyaku.External.{
    Gemini.Flash1_5,
    Gemini.Flash2,
    Rapid.FreeGoogleTranslator,
    Rapid.AiBitTranslator,
    Rapid.DeepLTranslator
  }

  @apis [Flash1_5, Flash2, FreeGoogleTranslator, AiBitTranslator, DeepLTranslator]

  @doc """
  翻译文本，使用指定的负载均衡算法。

  ## 参数
    - text: 要翻译的文本
    - target_lang: 目标语言
    - source_lang: 源语言
    - strategy: 负载均衡策略，支持 `:shuffle`

  ## 返回值
    - {:ok, translated_text} on success
    - {:error, reason} on failure
  """
  def translate(text, target_lang, source_lang, strategy \\ :shuffle) do
    case strategy do
      :shuffle ->
        shuffle_translate(@apis, text, target_lang, source_lang)

      _ ->
        {:error, :invalid_strategy}
    end
  end

  # 洗牌算法实现
  defp shuffle_translate(apis, text, target_lang, source_lang) do
    shuffled_apis = Enum.shuffle(apis)
    try_translate(shuffled_apis, text, target_lang, source_lang)
  end

  defp try_translate([], _text, _target_lang, _source_lang) do
    {:error, :all_apis_failed}
  end

  defp try_translate([api | rest], text, target_lang, source_lang) do
    case api.translate(text, target_lang, source_lang) do
      {:ok, translated_text} ->
        {:ok, translated_text}

      {:error, _reason} = error ->
        Logger.debug("翻译失败，原因：#{inspect(error)}，尝试下一个接口。")
        try_translate(rest, text, target_lang, source_lang)
    end
  end
end
