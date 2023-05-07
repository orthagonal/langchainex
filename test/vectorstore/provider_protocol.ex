defmodule VectorStoreProviderTest do
  use ExUnit.Case
  alias LangChain.VectorStore.Provider
  alias MockVectorStoreProvider

  setup do
    provider = %MockVectorStoreProvider{}
    {:ok, provider: provider}
  end

  test "add_vectors/2", %{provider: provider} do
    vector_list = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
    new_provider = Provider.add_vectors(provider, vector_list)

    assert new_provider.vectors == %{
             0 => [1, 2, 3],
             1 => [4, 5, 6],
             2 => [7, 8, 9]
           }
  end

  test "similarity_search/4", %{provider: provider} do
    result = Provider.similarity_search(provider, [0.5, 0.5, 0.5], 5, nil)
    assert result == []
  end

  test "similarity_search_with_score/4", %{provider: provider} do
    result = Provider.similarity_search_with_score(provider, [0.5, 0.5, 0.5], 5, nil)
    assert result == []
  end

  test "load/3", %{provider: provider} do
    result = Provider.load(provider, "some_directory", "some_embeddings")
    assert result == :ok
  end
end
