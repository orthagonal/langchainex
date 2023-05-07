defmodule LangChain.VectorStore.PineconeProvider do
  @behaviour LangChain.VectorStore.Provider
  alias HTTPoison
  alias Jason
  alias UUID


  def get_base(provider, operation) do
    {
      :ok, [
        api_key: api_key,
        index_name: index_name,
        project_id: project_id,
        environment: environment
      ]
    } = Application.fetch_env(:langchainex, :pinecone)

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

  def add_vectors(provider, vectors) when is_list(vectors) do
    pinecone_vectors = Enum.map(vectors, fn vector ->
      %{id: UUID.uuid4(), values: vector}
    end)
    add_pinecone_vectors(:default_provider, pinecone_vectors)
  end

  def add_pinecone_vectors(provider, vectors) do
    base = get_base(provider, "vectors/upsert")
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
end
