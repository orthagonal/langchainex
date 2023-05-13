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
  alias LangChain.Providers.OpenAI
  require Logger

  @model %OpenAI{
    model_name: "text-ada-001",
    max_tokens: 25,
    temperature: 0.5,
    n: 1
  }

  @gpt_model %OpenAI{
    model_name: "gpt-3.5-turbo",
    max_tokens: 25,
    temperature: 0.5,
    n: 1
  }

  describe "OpenAI implementation of LanguageModelProtocol" do
    test "call/2 returns a valid response" do
      prompt = "Write a sentence containing the word *grue*."
      assert {:ok, response} = LanguageModelProtocol.call(@model, prompt)
      assert String.length(response) > 0
      assert String.contains?(response, "grue")
    end

    test "chat/2 returns a valid response" do
      msgs = [
        %{text: "Write a sentence containing the word *grue*.", role: "user"},
        %{text: "Include a reference to the Dead Mountaineers Hotel."}
      ]

      assert {:ok, response} = LanguageModelProtocol.chat(@gpt_model, msgs)
      Logger.debug(response)
      assert is_list(response)
      assert length(response) > 0
      assert Enum.all?(response, &is_map/1)
      assert Enum.all?(response, &Map.has_key?(&1, :text))
      assert Enum.all?(response, &Map.has_key?(&1, :role))
    end
  end
end
