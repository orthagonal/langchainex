defmodule LangChain.VectorStore.PineconeProvider do

  defstruct config_name: :pinecone

  defimpl LangChain.VectorStore.Provider do
    alias HTTPoison
    alias Jason
    alias UUID

    defp get_base(config_name, operation) do
      {
        :ok, [
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

    def add_vectors(provider, vectors) do
      IO.puts "pinecone add vecdtors called"
      IO.inspect provider
      IO.inspect vectors
      pinecone_vectors = Enum.map(vectors, fn vector ->
        %{id: UUID.uuid4(), values: vector}
      end)
      add_pinecone_vectors(provider.config_name, pinecone_vectors)
    end

    def add_pinecone_vectors(config_name, vectors) do
      base = get_base(config_name, "vectors/upsert")
      body = %{
        "vectors" => Enum.map(vectors, &(%{"id" => &1.id, "values" => &1.values}))
      }
      |> Jason.encode!()

      res = HTTPoison.post(base.url, body, base.headers)
      # the call should yield the number of vectors added
      # otherwise it returns a helpful error message why not
      with {:ok, response} <- HTTPoison.post(base.url, body, base.headers) do
        decoded_response = Jason.decode!(response.body)
        size = decoded_response["upsertedCount"]
        if is_nil(size) do
          {:error, decoded_response }
        else
          {:ok, size }
        end
      else
        {:error, %HTTPoison.Error{reason: reason}} -> {:error, reason}
      end
    end

    def similarity_search(pinecone_db, query, k, filter) do
      IO.puts("similarity_search is called")
      {:ok, []}
    end

    def similarity_search_with_score(pinecone_db, query, k, filter) do
      IO.puts("similarity_search_with_score is called")
      {:ok, []}
    end

    def embed(pinecone_db, document_list) do
      IO.puts("embed is called")
      []
    end

    def load(pinecone_db, directory, embeddings) do
      IO.puts("load is called")
      :ok
    end

  end
end
