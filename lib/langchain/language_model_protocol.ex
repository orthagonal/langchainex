defprotocol LangChain.LanguageModelProtocol do
  defstruct provider: nil,
            model_name: nil,
            max_tokens: nil,
            temperature: nil,
            n: nil,
            options: nil

  def ask(model, prompt)
end
