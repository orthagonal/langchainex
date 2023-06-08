#  protocol for models that ingest audio and produce either audio or text
defprotocol LangChain.ImageModelProtocol do
  defstruct provider: nil,
            model_name: nil,
            max_tokens: nil,
            temperature: nil,
            n: nil,
            options: nil

  def describe(model, image_data) # take in image data and return text
  # def describe_stream(model, audio_data)
  # def speak(model, audio_data) # take in image data and return image
  # def speak_stream(model, audio_stream)
end
