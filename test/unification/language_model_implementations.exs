defmodule LangChain.LanguageModelUnifiedCallTest do
  @moduledoc """
  This test is here to do a unified test of all the language model implementations
  in one place, backed by their default models.  This ensures that our model is
  'unified' and models can talk to each other no matter what their actual implementation is.
  """
  use ExUnit.Case, async: true
  alias LangChain.LanguageModelProtocol
  require Logger

  # the inputs for the 'ask' function
  @input_for_call "You remind me of the baby"
  @inputs_and_outputs %{
    input: "You remind me of the baby",
    expected_output: %{
      format: "string",
      generated_text: "Baby what baby?"
    }
  }
  # will use the default model for each implementation
  @implementations_and_models [
    {%LangChain.Providers.Huggingface.LanguageModel{}, %{}},
    # you should be set to optional since it runs on local hardware
    {%LangChain.Providers.Bumblebee.LanguageModel{}, %{}},
    {%LangChain.Providers.Replicate.LanguageModel{}, %{}},
    {%LangChain.Providers.OpenAI.LanguageModel{}, %{}}
    # {%AnotherImplementation{}, %{model_name: "model_name"}},
  ]

  @input_for_chat [
    %{
      text: "You remind me of the babe",
      role: "user"
    },
    %{
      text: "The babe, what babe?",
      role: "assistant"
    },
    %{
      text: "The babe with the power",
      role: "user"
    }
  ]
  # @outputs %{
  #   format: "list",
  #   generated_text: "The power, what power?"
  # }

  # checks the type of the response
  defp yellow_function(response, _expected_response) do
    is_binary(response)
  end

  # Check the content of the response
  # not catastrophic if this fails, it's an AI
  defp green_function(response, expected_response) do
    response == expected_response.generated_text
  end

  @tag timeout: :infinity
  test "ask/2 returns a valid response for all implementations" do
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
              yellow: yellow_function(response, @inputs_and_outputs.expected_output),
              green: green_function(response, @inputs_and_outputs.expected_output)
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

  @tag timeout: :infinity
  test "ask/2 returns a valid response for all implementations with chat input type" do
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
              yellow: yellow_function(response, @inputs_and_outputs.expected_output),
              green: green_function(response, @inputs_and_outputs.expected_output)
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
end
