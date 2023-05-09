# any implementations that deal with filesystem access should go in this file
defmodule LangChain.Retriever.FileSystemProvider do
  @moduledoc """
  A filesystem implementation of the LangChain.Retriever protocol.
  """

  defstruct []

  defimpl LangChain.Retriever do
    @doc """
    Retrieves relevant documents from the file system based on the provided query.
    
    The query should be a map with the following keys:
      * `:path` (required) - The path to the file or directory to start the search from.
      * `:recursive` (optional, default: false) - If true, search for files in subdirectories as well.
      * `:file_extensions` (optional, default: []) - A list of file extensions to include in the results. If empty, all file extensions are included.
      * `:ignore_extensions` (optional, default: []) - A list of file extensions to exclude from the results.
    
    Examples:
    
        # Read the contents of a specific file
        Retriever.get_relevant_documents(provider, %{path: "path/to/file.ex"})
    
        # Read the contents of all files in a specific directory
        Retriever.get_relevant_documents(provider, %{path: "path/to/directory"})
    
        # Read the contents of all .ex files in a directory, including subdirectories
        Retriever.get_relevant_documents(provider, %{path: "path/to/directory", recursive: true, file_extensions: [".ex"]})
    
        # Read the contents of all files in a directory, excluding .js files
        Retriever.get_relevant_documents(provider, %{path: "path/to/directory", ignore_extensions: [".js"]})
    
    Returns a list of file contents or {:error, :invalid_path} if the provided path is invalid.
    """
    def get_relevant_documents(_provider, %{path: path} = query) do
      recursive = Map.get(query, :recursive, true)
      file_extensions = Map.get(query, :file_extensions, [])
      ignore_extensions = Map.get(query, :ignore_extensions, [])

      cond do
        File.regular?(path) ->
          # If the path is a file, read its contents and return it as a string inside a list
          process_file(path, file_extensions, ignore_extensions)

        File.dir?(path) ->
          # If the path is a directory, list its contents
          process_directory(path, recursive, file_extensions, ignore_extensions)

        true ->
          # If the path is neither a file nor a directory, return an error tuple
          {:error, :invalid_path}
      end
    end

    defp process_file(path, file_extensions, ignore_extensions) do
      if valid_file?(path, file_extensions, ignore_extensions) do
        {:ok, file_contents} = File.read(path)
        [file_contents]
      else
        []
      end
    end

    defp process_directory(path, recursive, file_extensions, ignore_extensions) do
      {:ok, files} = File.ls(path)

      Enum.reduce(files, [], fn file, acc ->
        file_path = Path.join(path, file)

        if File.dir?(file_path) and recursive do
          acc ++ process_directory(file_path, recursive, file_extensions, ignore_extensions)
        else
          acc ++ process_file(file_path, file_extensions, ignore_extensions)
        end
      end)
    end

    defp valid_file?(path, file_extensions, ignore_extensions) do
      extension = Path.extname(path)

      (Enum.empty?(file_extensions) or Enum.member?(file_extensions, extension)) and
        not Enum.member?(ignore_extensions, extension)
    end
  end
end

# # any implementations that deal with filesystem access should go in this file

# defmodule LangChain.Retriever.FileSystemProvider do
#   @moduledoc """
#   A filesystem implementation of the LangChain.Retriever protocol.
#   Use this to read in files and folders from your local filesystem as strings
#   so DocumentLoader can make machine-friendly vector embeddings out of them.
#   """

#   defstruct []

#   defimpl LangChain.Retriever do
#     def get_relevant_documents(_provider, path) do
#       cond do
#         File.regular?(path) ->
#           # If the path is a file, read its contents and return it as a string inside a list
#           {:ok, file_contents} = File.read(path)
#           [file_contents]

#         File.dir?(path) ->
#           # If the path is a directory, list its contents
#           {:ok, files} = File.ls(path)

#           Enum.reduce(files, [], fn file, acc ->
#             # For each file in the directory, read its contents and add it to the accumulator list
#             file_path = Path.join(path, file)
#             {:ok, file_contents} = File.read(file_path)
#             acc ++ [file_contents]
#           end)

#         true ->
#           # If the path is neither a file nor a directory, return an error tuple
#           {:error, :invalid_path}
#       end
#     end
#   end
# end
