# Embeddings are binary strings that have been converted to vectors of numbers so that neural networks can
# read them. An embedding must match the input size of the model and use the same encoding scheme, so you
# can implement EmbeddingProtocol for your own custom models as needed.

# Embedding providers currently included with this project include:
# - LangChain.Embedding.OpenAIProvider   -- embeds documents for openai models, see test/providers/openai.exs for an example

defprotocol LangChain.EmbeddingProtocol do
  @doc """
  Embed a list of documents
  """
  def embed_documents(provider, documents)

  @doc """
  Embed a single query
  """
  def embed_query(provider, query)
end
