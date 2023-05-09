defmodule LangChain.VectorStore do
  @moduledoc """
    ## VectorStore Genserver, provides all the services for storing and searching vectors
  
  You can specify a provider when you launch the GenServer in your Application tree,
  so you can have multiple VectorStore servers running in your application, each with a different provider.
  
    ## options:
    :provider           -- the actual vector db provider you are using, must implement the VectorStore.Provider protocol
    :embed_documents    -- optional function for embedding multiple docs presented as strings
    :embed_query        -- optional function for embedding a single query when presented as a string
  """

  use GenServer
  alias LangChain.VectorStore.Provider
  require Logger

  def start_link(opts \\ []) do
    provider = Keyword.get(opts, :provider) || default_provider()
    embed_documents = Keyword.get(opts, :embed_documents) || default_embed_documents()
    embed_query = Keyword.get(opts, :embed_query) || default_embed_query()
    GenServer.start_link(__MODULE__, {provider, embed_documents, embed_query}, opts)
  end

  defp default_provider do
    IO.warn(
      "No :provider option specified, will fallback to default provider from the application environment defined in :vector_store_provider."
    )

    Application.get_env(:lang_chain, :vector_store_provider)
  end

  defp default_embed_documents do
    fn
      _, _ -> []
    end
  end

  defp default_embed_query do
    fn
      _, _ -> []
    end
  end

  def init({provider, embed_documents, embed_query}) do
    state = %{
      provider: provider,
      embed_documents: embed_documents,
      embed_query: embed_query
    }

    {:ok, state}
  end

  # Public API
  def add_documents(pid, document_list) do
    GenServer.call(pid, {:add_documents, document_list})
  end

  @doc """
  Add a list of vectors to the vector store.
  """
  def add_vectors(pid, vector_list) do
    GenServer.call(pid, {:add_vectors, vector_list})
  end

  @doc """
  perform a similarity search on the vector store
  if query is a string it will be run through embed_query first
  """
  def similarity_search(pid, query, k, filter) when is_binary(query) do
    GenServer.call(pid, {:similarity_search_string, query, k, filter})
  end

  def similarity_search(pid, query, k, filter) when is_list(query) do
    GenServer.call(pid, {:similarity_search, query, k, filter})
  end

  @doc """
  perform a similarity search on the vector store and return score
  if query is a string it will be run through embed_query first
  """
  def similarity_search_with_score(pid, query, k, filter) when is_binary(query) do
    GenServer.call(pid, {:similarity_search_with_score_string, query, k, filter})
  end

  def similarity_search_with_score(pid, query, k, filter) when is_list(query) do
    GenServer.call(pid, {:similarity_search_with_score, query, k, filter})
  end

  @doc """
  load a vector store from a directory
  """
  def load(pid, directory, embeddings) do
    GenServer.call(pid, {:load, directory, embeddings})
  end

  # Callbacks
  def handle_call({:add_documents, document_list}, _from, state) do
    embeddings = state.embed_documents.(document_list, state.provider)
    result = _add_vectors(state, embeddings)
    {:reply, {:ok, result}, state}
  end

  def handle_call({:add_vectors, vector_list}, _from, state) do
    result = _add_vectors(state, vector_list)
    {:reply, {:ok, result}, state}
  end

  def handle_call({:similarity_search_string, query, k, filter}, _from, state) do
    embedding = state.embed_query.(query, state.provider)
    result = _similarity_search(state, embedding, k, filter)
    {:reply, result, state}
  end

  def handle_call({:similarity_search_with_score_string, query, k, filter}, _from, state) do
    embedding = state.embed_query.(query, state.provider)
    result = _similarity_search_with_score(state, embedding, k, filter)
    {:reply, result, state}
  end

  def handle_call({:similarity_search_with_score, query, k, filter}, _from, state) do
    result = _similarity_search_with_score(state, query, k, filter)
    {:reply, result, state}
  end

  def handle_call({:similarity_search, query, k, filter}, _from, state) do
    result = _similarity_search(state, query, k, filter)
    {:reply, result, state}
  end

  def handle_call({:load, directory, embeddings}, _from, state) do
    new_state = _load(state, directory, embeddings)
    {:reply, :ok, new_state}
  end

  # Private API
  defp _add_vectors(state, vector_list) do
    try do
      # Logger.debug("why no state???")
      Provider.add_vectors(state.provider, vector_list)
    rescue
      error ->
        Logger.error("Error occurred: #{inspect(error)}")
    end

    state
  end

  defp _similarity_search(state, query, k, filter) do
    Provider.similarity_search(state.provider, query, k, filter)
  end

  defp _similarity_search_with_score(state, query, k, filter) do
    Provider.similarity_search_with_score(state.provider, query, k, filter)
  end

  defp _load(state, directory, embeddings) do
    Provider.load(state.provider, directory, embeddings)
  end
end
