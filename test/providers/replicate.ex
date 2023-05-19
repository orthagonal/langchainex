# credo:disable-for-this-file
defmodule LangChain.Providers.ReplicateTest do
  @moduledoc """
  test replicate LLMs
  """
  use ExUnit.Case
  alias LangChain.LanguageModelProtocol
  alias LangChain.Providers.Replicate.LanguageModel
  require Logger

  @moduletag timeout: 230_000
  @hello_model %LanguageModel{
    model_name: "hello",
    version: "5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa"
  }

  @stablelm_tuned_alpha_7b %LanguageModel{
    model_name: "stablelm-tuned-alpha-7b",
    version: "c49dae362cbaecd2ceabb5bd34fdb68413c4ff775111fea065d259d577757beb"
  }

  # checks the type of the response
  defp yellow_function(response) do
    is_binary(response)
  end

  describe "Replicate implementation of LanguageModelProtocol" do
    @tag timeout: :infinity
    test "ask/2 returns a valid response for strings" do
      prompt = "Write a sentence containing the word *grue*."
      response = LanguageModelProtocol.ask(@hello_model, prompt)
      Logger.debug(response)
      assert yellow_function(response)

      response3 = LanguageModelProtocol.ask(@stablelm_tuned_alpha_7b, prompt)
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

      response4 = LanguageModelProtocol.ask(@stablelm_tuned_alpha_7b, msgs)
      Logger.debug(response4)
      assert yellow_function(response4)
    end
  end
end
