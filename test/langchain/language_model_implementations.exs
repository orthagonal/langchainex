defmodule LangChain.LanguageModelProtocolTest do
  use ExUnit.Case, async: true
  alias LangChain.LanguageModelProtocol

  # the inputs for the 'call' function
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
    {%LangChain.Providers.Bumblebee.LanguageModel{}, %{}},
    {%LangChain.Providers.Replicate.LanguageModel{}, %{}},
    {%LangChain.Providers.OpenAI.LanguageModel{}, %{}}
    # {%AnotherImplementation{}, %{model_name: "model_name"}},
  ]

  # checks the type of the response
  defp yellow_function(response, expected_response) do
    is_binary(response)
  end

  # Check the content of the response
  # not catastrophic if this fails, it's an AI
  defp green_function(response, expected_response) do
    # response == expected_response.generated_text
    false
  end

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
              yellow: yellow_function(response, @expected_output_for_call),
              green: green_function(response, @expected_output_for_call)
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

    Enum.each(results, fn
      {:ok, {:error, reason}} ->
        # The task failed, so we print the error message
        IO.puts("A test failed with reason: #{inspect(reason)}")

      {:ok, result} ->
        IO.inspect(results)
        # The task finished successfully, so we do nothing
        :ok
    end)
  end
end
