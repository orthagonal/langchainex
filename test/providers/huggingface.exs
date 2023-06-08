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

  @tag :skip
  @tag timeout: :infinity
  test "ask/2 returns a valid translation for a text" do
    input_for_translation = "Привет, мир"
    expected_output_for_translation = "Hello, world"

    model = LangChain.Providers.Huggingface.LanguageModel.new(:text_translation)

    try do
      response = LanguageModelProtocol.ask(model, input_for_translation)
      assert response =~ expected_output_for_translation
      Logger.debug("ask/2 results: #{inspect(response)}")
      :ok
    rescue
      error in [RuntimeError, SomeOtherError] ->
        flunk("Runtime error or some other error: #{Exception.message(error)}")
    catch
      kind, reason ->
        flunk("Caught #{kind}: #{inspect(reason)}")
    end
  end

  @tag :skip
  @tag timeout: :infinity
  test "ask/2 returns a valid answer for a table-based question" do
    input_for_table_qa = %{
      query: "What is the population of Paris?",
      table: %{
        "City" => ["San Francisco", "Paris", "Beijing"],
        "Country" => ["USA", "France", "China"],
        "Population" => ["883305", "2140526", "21540000"]
      }
    }

    expected_output_for_table_qa = "The population of Paris is 2,140,526."

    model = %LangChain.Providers.Huggingface.LanguageModel{
      language_action: :table_question_answering
    }

    try do
      response = LanguageModelProtocol.ask(model, input_for_table_qa)

      # Replace yellow_function and green_function with real assert functions
      assert response == expected_output_for_table_qa

      Logger.debug("ask/2 results: #{inspect(response)}")
      :ok
    rescue
      error in [RuntimeError, SomeOtherError] ->
        flunk("Runtime error or some other error: #{Exception.message(error)}")
    catch
      kind, reason ->
        flunk("Caught #{kind}: #{inspect(reason)}")
    end
  end

  def yellow_function(response, expected_output) do
    if response =~ expected_output do
      :ok
    else
      flunk("Expected #{inspect(expected_output)} but got #{inspect(response)}")
    end
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
              # yellow: yellow_function(response, @expected_output),
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

  @tag :skip
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
              # yellow: yellow_function(response, @expected_output),
              # green: green_function(response, @expected_output)
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
            chunks = audio_data
              |> Enum.chunk_every(50)
            IO.inspect chunks |> Enum.count()
            # response = AudioModelProtocol.speak(model, audio_data)
            # IO.puts(response)
            # %{
            #   model: %{provider: model.provider, model_name: model.model_name},
            #   response: response,
            #   yellow: yellow_function(response),
            #   green: green_function(response)
            # }
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
end

defmodule LangChain.ImageModelHuggingfaceTest do
  @moduledoc """
  Test a variety of Huggingface models to ensure they work as expected
  with the same 'call' interface but for images
  """
  use ExUnit.Case, async: true
  alias LangChain.ImageModelProtocol
  alias LangChain.Providers.Huggingface.ImageModel
  require Logger

  # get from cwd
  @image_file "./sample.jpg"

  @image_model_classify %LangChain.Providers.Huggingface.ImageModel{
    language_action: :image_classification
  }

  @tag timeout: :infinity
  test "classify/2 return valid responses for image files" do
    image_data = File.read!(@image_file)
    response_classify = ImageModelProtocol.describe(@image_model_classify, image_data)
    IO.inspect(response_classify)
  end
end
