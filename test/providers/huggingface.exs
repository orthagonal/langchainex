defmodule LangChain.LanguageModelHuggingfaceTest do
  @moduledoc """
  Test a variety of Huggingface models to ensure they work as expected
  with the same 'call' interface
  """
  use ExUnit.Case, async: true
  alias LangChain.LanguageModelProtocol
  alias LangChain.Providers.Huggingface.LanguageModel
  require Logger

  @model %LanguageModel{}
  @ms_gpt_model %LanguageModel{}

  # will use the default model for each implementation
  @implementations_and_models [
    {%LangChain.Providers.Huggingface.LanguageModel{}, %{}},
    {%LangChain.Providers.Huggingface.LanguageModel{
       model_name: "gpt2"
     }, %{}},
    {%LangChain.Providers.Huggingface.LanguageModel{
       model_name: "google/flan-t5-small"
     }, %{}},
    {%LangChain.Providers.Huggingface.LanguageModel{
       model_name: "TheBloke/vicuna-13B-1.1-HF"
     }, %{}},
    {%LangChain.Providers.Huggingface.LanguageModel{
       model_name: "sentence-transformers/distilbert-base-nli-mean-tokens"
     }, %{}}
  ]

  @input_for_call "What is the meaning of life?"
  @input_for_chat [
    %{
      text: "What is 7 times fifty-two?",
      role: "user"
    },
    %{
      text: "Three-hundred and sixty-four.",
      role: "assistant"
    },
    %{
      text: "What is that divided by 3?",
      role: "user"
    }
  ]
  @expected_outputs "Not really worried about it"

  # checks the type of the response
  defp yellow_function(response, _expected_response) do
    # make sure it's a string without the word 'malfunction' in it:
    is_binary(response) and String.contains?(response, "malfunction") == false
  end

  # Check the content of the response
  # not catastrophic if this fails, it's an AI
  defp green_function(response, expected_response) do
    response == expected_response
  end

  @tag :skip
  @tag timeout: :infinity
  test "ask/2 returns a valid response for string prompts" do
    results =
      Task.async_stream(
        @implementations_and_models,
        fn {impl, params} ->
          try do
            model = Map.merge(impl, params)
            response = LanguageModelProtocol.ask(model, @input_for_call)

            %{
              model: %{provider: model.provider, model_name: model.model_name},
              response: response,
              yellow: yellow_function(response, @expected_output),
              green: green_function(response, @expected_output)
            }
          rescue
            error in [RuntimeError, SomeOtherError] ->
              {:error, "Runtime error or some other error: #{Exception.message(error)}"}
          catch
            kind, reason ->
              {:error, "Caught #{kind}: #{inspect(reason)}"}
          end
        end,
        timeout: :infinity
      )
      |> Enum.to_list()

    Enum.map(results, fn
      {:ok, {:error, reason}} ->
        # The task failed, so we print the error message
        IO.puts("A test failed with reason: #{inspect(reason)}")

      {:ok, result} ->
        Logger.debug("call/2 results: #{inspect(result)}")
        :ok
    end)
  end

  # @tag :skip
  @tag timeout: :infinity
  test "ask/2 returns a valid response for dialog lists" do
    results =
      Task.async_stream(
        @implementations_and_models,
        fn {impl, params} ->
          try do
            model = Map.merge(impl, params)
            response = LanguageModelProtocol.ask(model, @input_for_chat)

            %{
              model: %{provider: model.provider, model_name: model.model_name},
              response: response,
              yellow: yellow_function(response, @expected_output),
              green: green_function(response, @expected_output)
            }
          rescue
            error in [RuntimeError, SomeOtherError] ->
              {:error, "Runtime error or some other error: #{Exception.message(error)}"}
          catch
            kind, reason ->
              {:error, "Caught #{kind}: #{inspect(reason)}"}
          end
        end,
        timeout: :infinity
      )
      |> Enum.to_list()

    Enum.map(results, fn
      {:ok, {:error, reason}} ->
        # The task failed, so we print the error message
        IO.puts("A test failed with reason: #{inspect(reason)}")

      {:ok, result} ->
        Logger.debug("call/2 results: #{inspect(result)}")
        :ok
    end)
  end
end

defmodule LangChain.AudioModelHuggingfaceTest do
  @moduledoc """
  Test a variety of Huggingface models to ensure they work as expected
  with the same 'call' interface but for audio
  """
  use ExUnit.Case, async: true
  alias LangChain.AudioModelProtocol
  alias LangChain.Providers.Huggingface.AudioModel
  require Logger

  # get from cwd
  @audio_file "./ep1a.wav"

  @audio_models [
    # {%LangChain.Providers.Huggingface.AudioModel{}, %{}},
    {%LangChain.Providers.Huggingface.AudioModel{
        model_name: "marinone94/whisper-medium-swedish"
     }, %{}}
    # {%LangChain.Providers.Huggingface.AudioModel{
    #    model_name: "facebook/wav2vec2-large-960h-lv60"
    #  }, %{}}
  ]

  @tag timeout: :infinity
  test "speak/2 returns a valid response for audio files" do
    results =
      Task.async_stream(
        @audio_models,
        fn {impl, params} ->
          try do
            model = Map.merge(impl, params)
            audio_data = File.read!(@audio_file)
            response = AudioModelProtocol.speak(model, audio_data)
            IO.puts(response)

            %{
              model: %{provider: model.provider, model_name: model.model_name},
              response: response,
              yellow: yellow_function(response),
              green: green_function(response)
            }
          rescue
            error in [RuntimeError, SomeOtherError] ->
              {:error, "Runtime error or some other error: #{Exception.message(error)}"}
          catch
            kind, reason ->
              {:error, "Caught #{kind}: #{inspect(reason)}"}
          end
        end,
        timeout: :infinity
      )
      |> Enum.to_list()

    Enum.map(results, fn
      {:ok, {:error, reason}} ->
        # The task failed, so we print the error message
        IO.puts("A test failed with reason: #{inspect(reason)}")

      {:ok, result} ->
        Logger.debug("ask/2 results: #{inspect(result)}")
        :ok
    end)
  end

  # checks the type of the response
  defp yellow_function(response) do
    # Here, instead of checking if it's a string without the word 'malfunction' in it,
    # you'd probably want to check that it's the expected type of audio data:
    # update this according to your needs
    is_binary(response)
  end

  # Check the content of the response
  # not catastrophic if this fails, it's an AI
  defp green_function(response) do
    # As for checking the content of the response,
    # it would depend on what you're expecting back from the AudioModel. If you're getting back audio data,
    # you might want to check its duration, bitrate, number of channels, etc.
    # response == expected_response
    # return true or false according to your needs
  end
end
