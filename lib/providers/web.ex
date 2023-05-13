# # any implementations that deal with fetching resources on the web should go in this file
# defmodule LangChain.Retriever.WebProvider do
#   @moduledoc """
#   An implementation of the LangChain.Retriever protocol for fetching resources on the web.
#   """

#   defstruct []

#   defimpl LangChain.Retriever do
#     @doc """
#     Retrieves relevant documents from the Internet.

#     The query should be a map with the following keys:
#       * `:url` (required) - The full url of the resource to start the search from.

#     Examples:

#         # Read the contents of a specific file
#         Retriever.get_relevant_documents(provider, %{url: "https://google.com"})

#     Returns the text of the page or { :error, <error>} if the provided path is invalid.
#     """
#     def get_relevant_documents(_provider, %{url: url} = _query) do
#       # fetch the url as text
#       {:ok, _file_contents} = HTTPoison.get(url)
#       IO.inspect("got here")
#       _file_contents
#       _file_contents.body
#     end
#   end
# end

# # # any implementations that deal with filesystem access should go in this file

# # defmodule LangChain.Retriever.WebProvider do
# #   @moduledoc """
# #   A filesystem implementation of the LangChain.Retriever protocol.
# #   Use this to read in files and folders from your local filesystem as strings
# #   so DocumentLoader can make machine-friendly vector embeddings out of them.
# #   """

# #   defstruct []

# #   defimpl LangChain.Retriever do
# #     def get_relevant_documents(_provider, path) do
# #       cond do
# #         File.regular?(path) ->
# #           # If the path is a file, read its contents and return it as a string inside a list
# #           {:ok, file_contents} = File.read(path)
# #           [file_contents]

# #         File.dir?(path) ->
# #           # If the path is a directory, list its contents
# #           {:ok, files} = File.ls(path)

# #           Enum.reduce(files, [], fn file, acc ->
# #             # For each file in the directory, read its contents and add it to the accumulator list
# #             file_path = Path.join(path, file)
# #             {:ok, file_contents} = File.read(file_path)
# #             acc ++ [file_contents]
# #           end)

# #         true ->
# #           # If the path is neither a file nor a directory, return an error tuple
# #           {:error, :invalid_path}
# #       end
# #     end
# #   end
# # end
