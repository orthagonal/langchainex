# any mock implementations you need for testing and stubbing purposes should go in this file
defmodule MockVectorStoreProvider do
  @moduledoc "A mock implementation of the LangChain.VectorStore.Provider protocol for testing purposes."

  defstruct vectors: %{}

  defimpl LangChain.VectorStore.Provider do
    def add_vectors(provider, vector_list) do
      %{vectors: existing_vectors} = provider

      new_vectors =
        vector_list
        |> Enum.with_index()
        |> Enum.into(%{}, fn {vector, index} -> {index, vector} end)

      %{provider | vectors: Map.merge(existing_vectors, new_vectors)}
    end

    def similarity_search(_provider, _query, _k, _filter) do
      []
    end

    def similarity_search_with_score(_provider, _query, _k, _filter) do
      []
    end

    def embed(_provider, document_list) do
      Enum.map(document_list, &{&1, :rand.uniform()})
    end

    def load(_provider, _directory, _embeddings) do
      :ok
    end
  end
end
