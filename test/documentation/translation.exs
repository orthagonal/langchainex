defmodule SelfDocumenting do
  use ExUnit.Case
  alias LangChain.LanguageModelProtocol

  @audio_file "./ep1a.wav"

  @tag timeout: :infinity
  test "can I swedish" do

    model = %LangChain.Providers.Huggingface.AudioModel{
       model_name: "marinone94/whisper-medium-swedish"
    }
    audio_data = File.read!(@audio_file)
    chunk_size = 1000
    File.stream!(@audio_file, [], chunk_size)
    |> Stream.each(fn(chunk) ->
      # Do something with the chunk
      response = AudioModelProtocol.speak(model, audio_data)
      IO.puts("*****")
      IO.inspect(response)
      IO.inspect(chunk, limit: :infinity)
    end)
    |> Stream.run()
  end
    # prompt = %LangChain.PromptTemplate{
    #   template: """
    #   You have been asked to write an Elixir program that transcribes
    #   Swedish audio into Swedish text and then produces an SRT subtitle file containing the correct subtitles and timings.
    #   You can turn Swedish audio into Swedish text this way:
    #   `{%LangChain.Providers.Huggingface.AudioModel{ model_name: "marinone94/whisper-medium-swedish" }`
    #   Followed by:
    #   `response = AudioModelProtocol.speak(model, audio_data)`.  'response' will be a binary containing the
    #   Swedish text.

    #   You have a large audio file called "./ep1a.wav" that needs to be transcribed and translated in chunks in such a way that you can
    #   reproduce the timing of each line of audio for the SRT format.
    #   Now write an Elixir program that breaks the audio into chunks, transcribes each chunk, and produces all of the correct
    #   timings for each chunk.
    #   """
    # }

    # model = %LangChain.Providers.OpenAI.LanguageModel{
    #   model_name: "gpt-3.5-turbo",
    #   max_tokens: 2000,
    #   temperature: 0.1,
    #   n: 1
    # }
    # {%LangChain.Providers.Huggingface.LanguageModel{
    #    model_name: "openai-gpt"
    #  }
    # {%LangChain.Providers.Bumblebee.LanguageModel{}
    # {%LangChain.Providers.Replicate.LanguageModel{}
    # {%LangChain.Providers.OpenAI.LanguageModel{}
    # {%LangChain.Providers.NlpCloud.LanguageModel{}
    # model = %LangChain.Providers.GooseAi.LanguageModel{}

    # result = LanguageModelProtocol.ask(model, prompt.template)
    # IO.inspect result
    # if LangChain.ProgramTemplate.can_execute(program_template) do
    #   result = LangChain.ProgramTemplate.execute(program_template)
    # else
  # end

  # def ask_for_program(program_description, previous_program \\ "", previous_error \\ "") do
  #   template =
  #     case previous_error do
  #       "" ->
  #         "
  #         Request: Write elixir code that <%= program_description %>.
  #         Only print the code by itself, no non-code text or surrounding quotes
  #         or other marks.
  #         ***[HERE]***
  #       "

  #       prev ->
  #         "
  #         Request: Write elixir code that <%= program_description %>.
  #         Previous attempt: #{previous_program}
  #         Error I got when running the previous attempt: #{previous_error}
  #         Fix the code so it works correctly without crashing.
  #         Remove any non-code text or characters or quotes.
  #         Put your diagnosis of what is wrong in a comment.
  #         Only print the updated code by itself, no non-code text or surrounding quotes
  #         ***[HERE]***
  #       "
  #     end

  #   request = EEx.eval_string(template, program_description: program_description)
  #   IO.puts("****************passing this request:")
  #   IO.inspect(request)
  #   program = LanguageModelProtocol.ask(@turbo, request)

  #   try do
  #     IO.inspect(program)
  #     res = Code.eval_string(program, turbo: @turbo, foo: [5.0, 2.3, 1.6, 7.4, 1.4])
  #     IO.inspect(res)
  #   rescue
  #     e ->
  #       error_message =
  #         Map.get(e, :message, Map.get(e, :description, Map.get(e, :reason, "unknown error")))

  #       # Logger.info("The evaluated code threw this error: #{e.message}")
  #       ask_for_program(program_description, program, error_message)
  #   end
  # end

  # def prepareTemplate(elixirTemplate, ) do
  # end
end
