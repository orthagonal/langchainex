defprotocol LangChain.LanguageModelProtocol do
  defstruct provider: nil,
            model_name: nil,
            max_tokens: nil,
            temperature: nil,
            n: nil,
            options: nil

  def chat(model, chats)
  def call(model, prompt)
end
