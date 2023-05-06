defmodule LangChain.DocumentEmbedderTest do
  use ExUnit.Case, async: true

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

      assert {:ok, embeddings} = LangChain.Embeddings.embed_documents(llm, documents)
      IO.inspect(embeddings)
      assert length(embeddings) == length(documents)
    end
  end
end
