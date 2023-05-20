# credo:disable-for-this-file
defmodule LangChain.Providers.GooseAiTest do
  @moduledoc """
  test GooseAi LLMs
  """
  use ExUnit.Case
  alias LangChain.LanguageModelProtocol
  alias LangChain.Providers.GooseAi.LanguageModel
  require Logger

  @moduletag timeout: 230_000
  @hello_model %LanguageModel{}

  @neo %LanguageModel{
    model_name: "gpt-neo-20b"
  }

  # checks the type of the response
  defp yellow_function(response) do
    is_binary(response)
  end

  describe "GooseAi implementation of LanguageModelProtocol" do
    @tag timeout: :infinity
    test "ask/2 returns a valid response for strings" do
      prompt = "Write a sentence containing the word *grue*."
      response = LanguageModelProtocol.ask(@hello_model, prompt)
      Logger.debug(response)
      assert yellow_function(response)

      response3 = LanguageModelProtocol.ask(@neo, prompt)
      Logger.debug(response3)
      assert yellow_function(response)
    end

    @tag timeout: :infinity
    test "ask/2 returns a valid response for chat lists" do
      msgs = [
        %{text: "Write a sentence containing the word *grue*.", role: "user"},
        %{text: "Include a reference to the Dead Mountaineers Hotel."}
      ]

      response = LanguageModelProtocol.ask(@hello_model, msgs)
      Logger.debug(response)
      assert yellow_function(response)

      response4 = LanguageModelProtocol.ask(@neo, msgs)
      Logger.debug(response4)
      assert yellow_function(response4)
    end
  end
end
