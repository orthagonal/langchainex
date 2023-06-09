# credo:disable-for-this-file
defmodule LangChain.Providers.CohereTest do
  @moduledoc """
  Test Cohere LLMs
  """
  use ExUnit.Case
  alias LangChain.LanguageModelProtocol
  alias LangChain.Providers.Cohere.LanguageModel
  require Logger

  @moduletag timeout: 230_000
  @cohere_model %LanguageModel{
    max_token: 25
  }

  # checks the type of the response
  defp yellow_function(response) do
    is_binary(response)
  end

  describe "Cohere implementation of LanguageModelProtocol" do
    @tag timeout: :infinity
    test "ask/2 returns a valid response for strings" do
      prompt = "Write a sentence containing the word *grue*."
      response = LanguageModelProtocol.ask(@cohere_model, prompt)
      IO.inspect(response)
      # Logger.debug(response)
      # assert yellow_function(response)
    end
  end
end
