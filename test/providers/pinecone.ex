defmodule VectorStoreProviderTest do
  @moduledoc false

  use ExUnit.Case
  alias LangChain.VectorStore.PineconeProvider
  alias LangChain.VectorStore.Provider

  setup do
    provider = %PineconeProvider{
      config_name: :pinecone
    }

    {:ok, provider: provider}
  end

  test "add_vectors/2", %{provider: provider} do
    # make 3 vectors of size 1536 each, since the openai davinci model uses that size vector
    vectors =
      Enum.map(1..3, fn _ ->
        Enum.map(1..1536, fn _ -> :rand.uniform() end)
      end)

    # the pinecone
    {:ok, added_vectors_count} = Provider.add_vectors(provider, vectors)

    assert added_vectors_count == length(vectors)
  end
end

defmodule PineconeVectorStoreTest do
  @moduledoc false

  use ExUnit.Case
  alias LangChain.VectorStore
  alias LangChain.VectorStore.PineconeProvider

  setup do
    mock_embed_documents = fn document_list, _provider ->
      Enum.map(document_list, &{&1, :rand.uniform()})
    end

    mock_embed_query = fn query, _provider ->
      {:ok, :rand.uniform()}
    end

    {:ok, pid} =
      VectorStore.start_link(
        provider: %PineconeProvider{
          config_name: :pinecone
        },
        embed_documents: mock_embed_documents,
        embed_query: mock_embed_query
      )

    {:ok, pid: pid}
  end

  test "add_vectors/2", %{pid: pid} do
    vector_list =
      Enum.map(1..3, fn _ ->
        Enum.map(1..1536, fn _ -> :rand.uniform() end)
      end)

    result = VectorStore.add_vectors(pid, vector_list)

    # assert added_vectors_count == length(vector_list)
    Process.sleep(5_000)
  end

  test "search_similarity/4", %{pid: pid} do
    query = Enum.map(1..1536, fn _ -> :rand.uniform() end)
    top_k = 10

    {:ok, result} = VectorStore.similarity_search(pid, query, top_k, [])
    assert length(result) == top_k
  end

  test "search_similarity_with_score/4", %{pid: pid} do
    query = Enum.map(1..1536, fn _ -> :rand.uniform() end)
    top_k = 10

    {:ok, result} = VectorStore.similarity_search_with_score(pid, query, top_k, [])
    assert length(result) == top_k
    assert Enum.all?(result, fn result -> result.score >= 0.0 and result.score <= 1.0 end)
  end
end
