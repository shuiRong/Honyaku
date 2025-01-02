defmodule Honyaku.External.Translate do
  alias Honyaku.External.Translate.Balancer

  def translate(nil, _target_lang, _source_lang) do
    {:error, :nil_text}
  end

  def translate(text, target_lang, source_lang) do
    Balancer.translate(text, target_lang, source_lang)
  end
end
