defmodule LangChain.Retriever.FileSystemProvider do
  defimpl LangChain.Retriever do
    def get_relevant_documents(path) do
      cond do
        File.regular?(path) ->
          # If the path is a file, read its contents and return it as a string inside a list
          {:ok, file_contents} = File.read(path)
          [file_contents]

        File.dir?(path) ->
          # If the path is a directory, list its contents
          {:ok, files} = File.ls(path)

          Enum.reduce(files, [], fn file, acc ->
            # For each file in the directory, read its contents and add it to the accumulator list
            file_path = Path.join(path, file)
            {:ok, file_contents} = File.read(file_path)
            acc ++ [file_contents]
          end)

        true ->
          # If the path is neither a file nor a directory, return an error tuple
          {:error, :invalid_path}
      end
    end
  end
end
