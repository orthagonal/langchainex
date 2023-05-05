defmodule LangChain.ChatTest do
  @moduledoc """
  Tests for LangChain.Chat
  """
  use ExUnit.Case

  # test "Test OpenAI" do
  #   model = %LangChain.LLM{
  #     provider: :openai,
  #     model_name: "text-ada-001",
  #     max_tokens: 10,
  #     temperature: 0.5
  #   }
  #   { :ok, response } = LLM.call(model, "print hello world")
  #   IO.inspect response
  #   keys = Map.keys(response)
  #   assert List.first(keys) == "choices"
  # end

  test "test gpt-3.5-turbo" do
    model = %LangChain.LLM{
      provider: :openai,
      model_name: "gpt-3.5-turbo"
    }

    {:ok, response} =
      LangChain.LLM.chat(model, [
        %{text: "Multiply 7 times 6", role: "system"},
        %{content: "Now add twelve to that", role: "user"},
        %{
          text:
            "Now print the square root of the final result, round it off to 2 decimal points and put a '#' character on either side",
          role: "assistant"
        }
      ])

    assert [
             %{
               role: "assistant"
             }
           ] = response

    assert response |> List.first() |> Map.get(:text) =~ "#7.35#"
  end
end
