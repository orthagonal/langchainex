defprotocol LangChain.AudioModelProtocol do
  defstruct provider: nil,
            model_name: nil,
            max_tokens: nil,
            temperature: nil,
            n: nil,
            options: nil

  def speak(model, audio_data)
  def stream(model, audio_stream)
end
