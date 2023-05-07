  #  Retrievers take in a query and return a list of binary strings ("documents"), they
  #  are implemented as a protocol so that they can be swapped out for different implementations.
  #  The data source can be anything (a file, a database, an FTP site, a video camera, a haptic sensor, etc)
  #  so long as the data can be represented as a binary string.  It doesn't just have to be text!

  # Retrievers are primarily used by DocumentLoader to get strings and convert them to embeddings (embeddings are vectors
  # of numbers) so they can be fed to different neural networks.

  # Retriever implementations currently included with this project include:
  # - LangChain.Retriever.FileSystemProvider   -- can get the contents of a file or a list of all the contents of all the files in the directory

  defprotocol LangChain.Retriever do
  @doc """
    Takes a string query and returns a list of relevant documents
  """
  def get_relevant_documents(provider, query)
end
