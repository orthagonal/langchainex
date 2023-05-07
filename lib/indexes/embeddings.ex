defprotocol LangChain.EmbeddingProtocol do
  @doc """
  Embed a list of documents
  """
  def embed_documents(provider, model, documents)

  @doc """
  Embed a single query
  """
  def embed_query(provider, model, query)
end

# defmodule LangChain.Embeddings do
#   @moduledoc """
#     The Embeddings module provides an abstract base for embedding documents.  An embedding is a vector
#     representation of a document, you plug them in to a language model so that you can ask questions about
#     the content of your documents.
#   """

#   @derive Jason.Encoder
#   defstruct embeddings: [],
#             model: %LangChain.LLM{}

#   @doc """
#     embed a list of documents
#   """
#   def embed_documents(model, documents) when is_list(documents) do
#     case model.provider do
#       :openai -> LangChain.Providers.OpenAI.embed_documents(model, documents)
#       _ -> "unknown provider #{model.provider}"
#     end
#   end

#   @doc """
#   embed a single query
#   """
#   def embed_query(model, query) do
#     case model.provider do
#       :openai -> LangChain.Providers.OpenAI.embed_query(model, query)
#       _ -> "unknown provider #{model.provider}"
#     end
#   end
# end
