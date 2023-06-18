# credo:disable-for-this-file
defmodule LangChain.Providers.AlephAlpha do
  @moduledoc """
  test AlephAlpha LLMs
  """
  use ExUnit.Case
  alias LangChain.LanguageModelProtocol
  alias LangChain.Providers.AlephAlpha.LanguageModel
  require Logger

  @moduletag timeout: 230_000
  @luminous_model %LanguageModel{}

  # checks the type of the response
  defp yellow_function(response) do
    is_binary(response)
  end

  describe "AlephAlpha implementation of LanguageModelProtocol" do
    @tag timeout: :infinity
    test "ask/2 returns a valid response for strings" do
      prompt = "Four score and seven years ago"
      response = LanguageModelProtocol.ask(@luminous_model, prompt)
      Logger.debug(response)
      assert yellow_function(response)
    end

    @tag timeout: :infinity
    test "ask/2 returns a valid response for chat lists" do
      msgs = [
        %{text: "Write a sentence containing the word *grue*.", role: "user"},
        %{text: "Include a reference to the Dead Mountaineers Hotel."}
      ]

      response = LanguageModelProtocol.ask(@luminous_model, msgs)
      Logger.debug(response)
      assert yellow_function(response)
    end
  end
end

chandeliers on the ceiling
pink champaigne on ice
and he said
look at this top secret military document
reserved for Five Eyes
