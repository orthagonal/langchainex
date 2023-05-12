# any weaviate-specific code goes in this file

defmodule LangChain.VectorStore.WeaviateProvider do
  @moduledoc """
  A Weaviate implementation of the LangChain.VectorStore.Provider protocol.
  the 'config' argument just needs to be a struct with the config_name (ie :weaviate)
  for the specific db you want to use, this implementation will grab that config from
  config.exs for you.  You can have multiple weaviate configs in config.exs, just make
  and multiple implementations of this module, each with a different config_name.
  """
  defstruct config_name: :weaviate

  defimpl LangChain.VectorStore.Provider do
    alias HTTPoison
    alias Jason
    alias UUID

    defp get_base(config_name, operation) do
      IO.inspect(Application.fetch_env(:langchainex, config_name))

      {
        :ok,
        [
          api_key: api_key,
          index_name: index_name,
          client: client,
          text_key: text_key
        ]
      } = Application.fetch_env(:langchainex, config_name)

      %{
        url: "#{client}/v1/#{operation}",
        headers: [
          {"Accept", "application/json"},
          {"Content-Type", "application/json"},
          {"Authorization", "Bearer #{api_key}"}
        ],
        index_name: index_name,
        text_key: text_key
      }
    end

    def specify(config) do
      body = %{
        "class" => "Langchainex",
        "properties" => [
          %{
            "dataType" => ["text"],
            "name" => "title"
          },
          %{
            "dataType" => ["text"],
            "name" => "body"
          }
        ]
      }

      base = get_base(config.config_name, "schema")

      case HTTPoison.post(base.url, body, base.headers) do
        {:ok, response} ->
          IO.inspect(response)
          decoded_response = Jason.decode!(response.body)
          IO.inspect(decoded_response)
          {:ok, decoded_response}

        # size = decoded_response["upsertedCount"]

        # if is_nil(size) do
        #   {:error, decoded_response}
        # else
        #   {:ok, size}
        # end

        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, reason}
      end

      IO.inspect("specify")
    end

    def add_vectors(config, vectors) do
      base = get_base(config.config_name, "batch/objects")

      body =
        %{
          "objects" =>
            Enum.map(vectors, fn vector ->
              %{
                class: base.index_name,
                id: UUID.uuid4(),
                vector: vector,
                properties: []
                # you could probably pass vecotrs with metadata here like so:
                # properties: Map.put(flattened_metadata, @text_key, vector[:page_content])
              }
            end)
        }
        |> Jason.encode!()

      case HTTPoison.post(base.url, body, base.headers) do
        {:ok, response} ->
          IO.inspect(response)
          decoded_response = Jason.decode!(response.body)
          IO.inspect(decoded_response)
          {:ok, decoded_response}

        # size = decoded_response["upsertedCount"]

        # if is_nil(size) do
        #   {:error, decoded_response}
        # else
        #   {:ok, size}
        # end

        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, reason}
      end

      # add_weaviate_vectors(config.config_name, pinecone_vectors)
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

      case HTTPoison.post(base.url, body, base.headers) do
        {:ok, response} ->
          results = Jason.decode!(response.body)["matches"]

          if include_scores do
            {:ok,
             Enum.map(results, fn result ->
               %{score: Map.get(result, "score", 0), vector: Map.get(result, "values", [])}
             end)}
          else
            {:ok, Enum.map(results, fn result -> Map.get(result, "values", []) end)}
          end

        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, reason}
      end
    end

    def embed(_weaviate_db, _document_list) do
      throw("PineconeProvider.embed is called but has not been implemented")
      []
    end

    def load(_weaviate_db, _directory, _embeddings) do
      throw("PineconeProvider.load is called but has not been implemented")
      []
    end
  end
end
