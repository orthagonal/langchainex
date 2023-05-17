# LANGOLYMPICS!
defmodule LangChain.LanguageModelUnifiedCallTest do
  @moduledoc """
  This test is here to measure performance and timing with default models
  and provide a template for you to check the performance of your own models.
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
    },
    %{
      text: "The power, what power?",
      role: "assistant"
    },
    %{
      text: "The power of voodoo",
      role: "user"
    },
    %{
      text: "Who do?",
      role: "assistant"
    },
    %{
      text: "You do",
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
  test "ask/2 returns a valid response for all implementations and measures time with increasing inputs" do
    # start timer
    {total_time, _} =
      :timer.tc(fn ->
        Enum.each(0..(length(@input_for_chat) - 1), fn n ->
          input = Enum.take(@input_for_chat, n + 1)

          results =
            Task.async_stream(
              @implementations_and_models,
              fn {impl, params} ->
                try do
                  model = Map.merge(impl, params)
                  {time, response} = :timer.tc(fn -> LanguageModelProtocol.ask(model, input) end)

                  time_in_seconds = time / 1_000_000

                  %{
                    model: %{provider: model.provider, model_name: model.model_name},
                    response: response,
                    num_inputs: n + 1,
                    time: time_in_seconds,
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
              Logger.debug(
                "Batch size: #{result.num_inputs}, Provider: #{result.model.provider}, Model: #{result.model.model_name},
            Response: #{result.response},
            Time Elapsed: #{result.time} seconds"
              )

              :ok
          end)
        end)
      end)

    # end timer

    total_time_in_seconds = total_time / 1_000_000
    Logger.debug("Total Time Elapsed for all tasks: #{total_time_in_seconds} seconds")
  end
end
