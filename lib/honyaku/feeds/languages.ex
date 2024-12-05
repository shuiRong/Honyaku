defmodule Language do
  defstruct code: "", name: ""
end

defmodule LanguageMap do
  @moduledoc """
  语言代码映射
  https://developers.deepl.com/docs/resources/supported-languages#target-languages
  """

  @languages %{
    :AR => %Language{code: "AR", name: "Arabic"},
    :BG => %Language{code: "BG", name: "Bulgarian"},
    :CS => %Language{code: "CS", name: "Czech"},
    :DA => %Language{code: "DA", name: "Danish"},
    :DE => %Language{code: "DE", name: "German"},
    :EL => %Language{code: "EL", name: "Greek"},
    :EN => %Language{code: "EN", name: "English"},
    :"EN-GB" => %Language{code: "EN-GB", name: "English (British)"},
    :"EN-US" => %Language{code: "EN-US", name: "English (American)"},
    :ES => %Language{code: "ES", name: "Spanish"},
    :ET => %Language{code: "ET", name: "Estonian"},
    :FI => %Language{code: "FI", name: "Finnish"},
    :FR => %Language{code: "FR", name: "French"},
    :HU => %Language{code: "HU", name: "Hungarian"},
    :ID => %Language{code: "ID", name: "Indonesian"},
    :IT => %Language{code: "IT", name: "Italian"},
    :JA => %Language{code: "JA", name: "Japanese"},
    :KO => %Language{code: "KO", name: "Korean"},
    :LT => %Language{code: "LT", name: "Lithuanian"},
    :LV => %Language{code: "LV", name: "Latvian"},
    :NB => %Language{code: "NB", name: "Norwegian Bokmål"},
    :NL => %Language{code: "NL", name: "Dutch"},
    :PL => %Language{code: "PL", name: "Polish"},
    :PT => %Language{code: "PT", name: "Portuguese"},
    :"PT-BR" => %Language{code: "PT-BR", name: "Portuguese (Brazilian)"},
    :"PT-PT" => %Language{code: "PT-PT", name: "Portuguese (European)"},
    :RO => %Language{code: "RO", name: "Romanian"},
    :RU => %Language{code: "RU", name: "Russian"},
    :SK => %Language{code: "SK", name: "Slovak"},
    :SL => %Language{code: "SL", name: "Slovenian"},
    :SV => %Language{code: "SV", name: "Swedish"},
    :TR => %Language{code: "TR", name: "Turkish"},
    :UK => %Language{code: "UK", name: "Ukrainian"},
    :ZH => %Language{code: "ZH", name: "Chinese"},
    :"ZH-HANS" => %Language{code: "ZH-HANS", name: "Chinese (simplified)"},
    :"ZH-HANT" => %Language{code: "ZH-HANT", name: "Chinese (traditional)"}
  }

  def get_language(code) do
    @languages[code]
  end
end
