defmodule VectorStoreTest do
  use ExUnit.Case
  alias LangChain.VectorStore
  alias MockVectorStoreProvider

  setup do
    mock_embed_documents = fn document_list, _provider ->
      Enum.map(document_list, &{&1, :rand.uniform()})
    end

    mock_embed_query = fn query, _provider ->
      {:ok, :rand.uniform()}
    end

    {:ok, pid} =
      VectorStore.start_link(
        provider: %MockVectorStoreProvider{},
        embed_documents: mock_embed_documents,
        embed_query: mock_embed_query
      )

    {:ok, pid: pid}
  end

  test "add_documents/2", %{pid: pid} do
    document_list = ["doc1", "doc2", "doc3"]
    assert {:ok, _} = VectorStore.add_documents(pid, document_list)
  end

  test "add_vectors/2", %{pid: pid} do
    vector_list = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
    assert {:ok, _} = VectorStore.add_vectors(pid, vector_list)
  end

  test "similarity_search/4 with query as string", %{pid: pid} do
    result = VectorStore.similarity_search(pid, "query", 5, nil)
    assert result == []
  end

  test "similarity_search/4 with query as vector", %{pid: pid} do
    result = VectorStore.similarity_search(pid, [0.5, 0.5, 0.5], 5, nil)
    assert result == []
  end

  test "similarity_search_with_score/4 with query as string", %{pid: pid} do
    result = VectorStore.similarity_search_with_score(pid, "query", 5, nil)
    assert result == []
  end

  test "similarity_search_with_score/4 with query as vector", %{pid: pid} do
    result = VectorStore.similarity_search_with_score(pid, [0.5, 0.5, 0.5], 5, nil)
    assert result == []
  end

  test "load/3", %{pid: pid} do
    assert :ok = VectorStore.load(pid, "some_directory", "some_embeddings")
  end
end
