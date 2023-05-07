defprotocol LangChain.VectorStore.Provider do
  #  The Protocol for a VectorStore Provider, you can implement your own
  #  backend providers for storing and searching vectors by implementing the following protocol:

  @doc """
    add a list of vectors to the provider
    result is the number of vectors added
  """
  def add_vectors(config, vector_list)

  @doc """
    search for the top k most similar vectors to the query vector
    result is a simple list of vectors
  """
  def similarity_search(config, query, k, filter)

  @doc """
    search for the top k most similar vectors to the query vector
    result is a list of %{ score: X.XX, vector: [....]} maps
  """
  def similarity_search_with_score(config, query, k, filter)

  @doc """
    load a vector store from a directory
  """
  def load(config, directory, embeddings)
end
