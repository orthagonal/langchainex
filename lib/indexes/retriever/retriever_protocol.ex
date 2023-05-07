defprotocol LangChain.Retriever do
  #  The Protocol for a Retriever, you can implement your own
  #  backend retrievers to query and return lists of documents

  @doc """
    Takes a string query and returns a list of documents
  """
  def get_relevant_documents(query)

end
