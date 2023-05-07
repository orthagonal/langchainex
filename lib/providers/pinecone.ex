# any pinecone-specific code goes in this file

defmodule LangChain.VectorStore.PineconeProvider do
  @moduledoc """
  A Pinecone implementation of the LangChain.VectorStore.Provider protocol.
  the 'config' argument just needs to be a struct with the config_name (ie :pinecone)
  for the specific db you want to use, this implementation will grab that config from
  config.exs for you.  You can have multiple pinecone configs in config.exs, just make
  and multiple implementations of this module, each with a different config_name.
  """
  defstruct config_name: :pinecone

  defimpl LangChain.VectorStore.Provider do
    alias HTTPoison
    alias Jason
    alias UUID

    defp get_base(config_name, operation) do
      {
        :ok,
        [
          api_key: api_key,
          index_name: index_name,
          project_id: project_id,
          environment: environment
        ]
      } = Application.fetch_env(:langchainex, config_name)

      base_url = "https://#{index_name}-#{project_id}.svc.#{environment}.pinecone.io"

      %{
        url: "#{base_url}/#{operation}",
        headers: [
          {"Accept", "application/json"},
          {"Content-Type", "application/json"},
          {"Api-Key", api_key}
        ]
      }
    end

    def add_vectors(config, vectors) do
      pinecone_vectors =
        Enum.map(vectors, fn vector ->
          %{id: UUID.uuid4(), values: vector}
        end)

      add_pinecone_vectors(config.config_name, pinecone_vectors)
    end

    defp add_pinecone_vectors(config_name, vectors) do
      base = get_base(config_name, "vectors/upsert")

      body =
        %{
          "vectors" => Enum.map(vectors, &%{"id" => &1.id, "values" => &1.values})
        }
        |> Jason.encode!()

      res = HTTPoison.post(base.url, body, base.headers)
      # the call should yield the number of vectors added
      # otherwise it returns a helpful error message why not
      with {:ok, response} <- HTTPoison.post(base.url, body, base.headers) do
        decoded_response = Jason.decode!(response.body)
        size = decoded_response["upsertedCount"]

        if is_nil(size) do
          {:error, decoded_response}
        else
          {:ok, size}
        end
      else
        {:error, %HTTPoison.Error{reason: reason}} -> {:error, reason}
      end
    end

    def similarity_search(config, query, k, _filter) do
      similarity_search_impl(config.config_name, query, k, false)
    end

    def similarity_search_with_score(config, query, k, _filter) do
      similarity_search_impl(config.config_name, query, k, true)
    end

    defp similarity_search_impl(config_name, query, k, include_scores) do
      base = get_base(config_name, "query")

      body =
        %{
          "vector" => query,
          "topK" => k,
          "includeValues" => "true",
          "includeMetadata" => "false"
        }
        |> Jason.encode!()

      with {:ok, response} <- HTTPoison.post(base.url, body, base.headers) do
        decoded_response = Jason.decode!(response.body)
        results = decoded_response["matches"]

        if include_scores do
          {:ok,
           Enum.map(results, fn result ->
             %{score: Map.get(result, "score", 0), vector: Map.get(result, "values", [])}
           end)}
        else
          {:ok, Enum.map(results, fn result -> Map.get(result, "values", []) end)}
        end
      else
        {:error, %HTTPoison.Error{reason: reason}} -> {:error, reason}
      end
    end

    def embed(pinecone_db, document_list) do
      throw("PineconeProvider.embed is called but has not been implemented")
      []
    end

    def load(pinecone_db, directory, embeddings) do
      IO.puts("load is called")
      :ok
    end
  end
end
