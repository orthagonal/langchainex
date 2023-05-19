defmodule LangChain.Embedder.OpenAIProviderTest do
  @moduledoc """
  test openai embeddings
  """

  use ExUnit.Case, async: true

  alias LangChain.EmbedderProtocol

  alias LangChain.Embedder.OpenAIProvider

  describe "embed_documents/2" do
    test "embeds documents with OpenAI provider" do
      documents = [
        "This is a sample document.",
        "This is another sample document."
      ]

      openai_provider = %OpenAIProvider{
        model_name: "text-embedding-ada-002"
      }

      assert {:ok, embeddings} = EmbedderProtocol.embed_documents(openai_provider, documents)
      assert length(embeddings) == length(documents)
      # assert it's a vector of vectors containing floats
      assert Enum.all?(embeddings, &is_list/1)

      assert Enum.all?(embeddings, fn embedding ->
               Enum.all?(embedding, &is_float/1)
             end)
    end
  end
end

defmodule LangChain.Providers.OpenAITest do
  @moduledoc """
  test openai LLMs
  """
  use ExUnit.Case
  alias LangChain.LanguageModelProtocol
  alias LangChain.Providers.OpenAI.LanguageModel
  require Logger

  @model %LanguageModel{
    model_name: "text-ada-001",
    max_tokens: 25,
    temperature: 0.5,
    n: 1
  }

  @gpt_model %LanguageModel{
    model_name: "gpt-3.5-turbo",
    max_tokens: 25,
    temperature: 0.5,
    n: 1
  }

  @davinci_model %LanguageModel{
    model_name: "davinci",
    max_tokens: 25,
    temperature: 0.5,
    n: 1
  }

  # checks the type of the response
  defp yellow_function(response) do
    is_binary(response)
  end

  # Check the content of the response
  # not catastrophic if this fails, it's an AI
  # credo:disable-for-next-line
  defp green_function(response, expected_response) do
    String.contains?(response, expected_response)
  end

  describe "OpenAI implementation of LanguageModelProtocol" do
    test "ask/2 returns a valid response with string prompt for different models" do
      prompt = "Write a sentence containing the word *grue*."

      response = LanguageModelProtocol.ask(@model, prompt)
      assert yellow_function(response)
      assert green_function(response, "grue")

      response2 = LanguageModelProtocol.ask(@davinci_model, prompt)
      assert yellow_function(response2)
      assert green_function(response, "grue")

      response3 = LanguageModelProtocol.ask(@gpt_model, prompt)
      assert yellow_function(response3)
      assert green_function(response, "grue")
    end

    test "ask/2 returns a valid response with list of chats" do
      msgs = [
        %{text: "Write a sentence containing the word *grue*.", role: "user"},
        %{text: "Include a reference to the Dead Mountaineers Hotel."}
      ]

      response = LanguageModelProtocol.ask(@model, msgs)
      assert yellow_function(response)
      # assert green_function(response, "grue")

      response2 = LanguageModelProtocol.ask(@davinci_model, msgs)
      assert yellow_function(response2)
      # assert green_function(response, "grue")

      response3 = LanguageModelProtocol.ask(@gpt_model, msgs)
      assert yellow_function(response3)
      # assert green_function(response, "grue")
    end
  end
end
