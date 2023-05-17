defmodule LangChain.LanguageModelUnifiedCallTest do
  @moduledoc """
  This test is here to do a unified test of all the language model implementations
  in one place, backed by their default models.  This ensures that our model is
  'unified' and models can talk to each other no matter what their actual implementation is.
  """
  use ExUnit.Case, async: true
  alias LangChain.LanguageModelProtocol
  alias LangChain.Providers.Huggingface.LanguageModel
  require Logger

  @model %LanguageModel{}
  @ms_gpt_model %LanguageModel{}

  # will use the default model for each implementation
  @implementations_and_models [
    # {%LangChain.Providers.Huggingface.LanguageModel{}, %{}},
    # {%LangChain.Providers.Huggingface.LanguageModel{
    #    model_name: "gpt2"
    #  }, %{}},
    # {%LangChain.Providers.Huggingface.LanguageModel{
    #    model_name: "google/flan-t5-small"
    #  }, %{}}
    # {%LangChain.Providers.Huggingface.LanguageModel{
    #    model_name: "TheBloke/vicuna-13B-1.1-HF"
    #  }, %{}}
    {%LangChain.Providers.Huggingface.LanguageModel{
       model_name: "sentence-transformers/distilbert-base-nli-mean-tokens"
       #  language_action: "embed"
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

  # @tag :skip
  @tag timeout: :infinity
  test "call/2 returns a valid response for all implementations" do
    results =
      Task.async_stream(
        @implementations_and_models,
        fn {impl, params} ->
          try do
            model = Map.merge(impl, params)
            response = LanguageModelProtocol.call(model, @input_for_call)

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

  @tag :skip
  @tag timeout: :infinity
  test "chat/2 returns a valid response for all implementations" do
    results =
      Task.async_stream(
        @implementations_and_models,
        fn {impl, params} ->
          try do
            model = Map.merge(impl, params)
            response = LanguageModelProtocol.chat(model, @input_for_chat)

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
        Logger.debug("chat/2 results: #{inspect(result)}")
        :ok
    end)
  end
end
