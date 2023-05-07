defmodule LangChain.Embedding.OpenAIProviderTest do
  use ExUnit.Case, async: true

  alias LangChain.EmbeddingProtocol
  alias LangChain.Embedding.OpenAIProvider

  describe "embed_documents/2" do
    test "embeds documents with OpenAI provider" do
      llm = %LangChain.LLM{
        provider: :openai,
        temperature: 0.1,
        max_tokens: 200,
        # only certain models support embedding on openai
        model_name: "text-embedding-ada-002"
      }

      documents = [
        "This is a sample document.",
        "This is another sample document."
      ]

      openai_provider = %OpenAIProvider{}

      assert {:ok, embeddings} =
               EmbeddingProtocol.embed_documents(openai_provider, llm, documents)

      IO.inspect(embeddings)
      assert length(embeddings) == length(documents)
    end
  end
end
