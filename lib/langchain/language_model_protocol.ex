#  the home for protocols that ingest text and produce text, audio or image

# text to text
defprotocol LangChain.LanguageModelProtocol do
  defstruct provider: nil,
            model_name: nil,
            max_tokens: nil,
            temperature: nil,
            n: nil,
            options: nil

  def ask(model, prompt)
end

# text to image
defprotocol LangChain.TextToImageProtocol do
  defstruct provider: nil,
            model_name: nil,
            max_tokens: nil,
            temperature: nil,
            n: nil,
            options: nil

  def ask(model, prompt)
end

# text to audio
defprotocol LangChain.TextToAudioProtocol do
  defstruct provider: nil,
            model_name: nil,
            max_tokens: nil,
            temperature: nil,
            n: nil,
            options: nil

  def ask(model, prompt)
end
