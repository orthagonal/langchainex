# credo:disable-for-this-file
defmodule LangChain.Providers.NlpCloudTest do
  @moduledoc """
  test NlpCloud LLMs
  """
  use ExUnit.Case
  alias LangChain.LanguageModelProtocol
  alias LangChain.Providers.NlpCloud.LanguageModel
  require Logger

  @moduletag timeout: 230_000
  @hello_model %LanguageModel{}

  @fast_gpt_j %LanguageModel{
    model_name: "fast-gpt-j"
  }

  # checks the type of the response
  defp yellow_function(response) do
    is_binary(response)
  end

  describe "NlpCloud implementation of LanguageModelProtocol" do
    @tag timeout: :infinity
    test "ask/2 returns a valid response for strings" do
      prompt = "Write a sentence containing the word *grue*."
      response = LanguageModelProtocol.ask(@hello_model, prompt)
      Logger.debug(response)
      assert yellow_function(response)

      response3 = LanguageModelProtocol.ask(@fast_gpt_j, prompt)
      Logger.debug(response3)
      assert yellow_function(response)
    end

    @tag timeout: :infinity
    test "ask/2 returns a valid response for chat lists" do
      msgs = [
        %{text: "Write a sentence containing the word *grue*.", role: "user"},
        %{text: "Include a reference to the novel Dead Mountaineer's Inn."}
      ]

      response = LanguageModelProtocol.ask(@hello_model, msgs)
      Logger.debug(response)
      assert yellow_function(response)

      response4 = LanguageModelProtocol.ask(@fast_gpt_j, msgs)
      Logger.debug(response4)
      assert yellow_function(response4)
    end
  end
end
