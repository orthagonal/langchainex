defprotocol LangChain.VectorStore.Provider do
  #  The Protocol for a VectorStore Provider, you can implement your own
  #  backend providers for storing and searching vectors by implementing the following protocol:
  def add_vectors(provider, vector_list)
  def similarity_search(provider, query, k, filter)
  def similarity_search_with_score(provider, query, k, filter)
  def embed(provider, document_list)
  def load(provider, directory, embeddings)
end
