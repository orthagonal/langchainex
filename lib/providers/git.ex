defmodule LangChain.Git do
  def get_repo_files(branch, path \\ "") do
    # Get the contents of the current directory
    repo_instance = Gitex.Git.open()
    contents = Gitex.get(branch, repo_instance, path)

    # Use Enum.reduce/3 to accumulate all the file paths
    Enum.reduce(contents, [], fn item, acc ->
      case item.type do
        # If the item is a file, add its path to the accumulator
        :file ->
          [Path.join(path, item.name) | acc]

        # If the item is a directory, recurse into it and add its files to the accumulator
        :dir ->
          dir_files = get_repo_files(branch, Path.join(path, item.name))
          acc ++ dir_files

        # If the item type is unknown, just return the accumulator
        _ ->
          acc
      end
    end)
  end
end

defmodule LangChain.Retriever.Git do
  @moduledoc """
  Gitex is a wrapper around the Elixir Git library.
  """
  @behaviour LangChain.Retriever

  defstruct []


  defimpl LangChain.Retriever do
    def get_relevant_documents(_provider, %{"type" => "blob", "branch" => branch, "path" => path}) do
      repo_instance = Gitex.Git.open()
      blob = Gitex.get(branch, repo_instance, path)
      [blob]
    end

    def get_relevant_documents(_provider, %{"type" => _tree, "branch" => branch, "path" => path}) do
      repo_instance = Gitex.Git.open()
      Gitex.get(branch, repo_instance, path)
    end

    def get_relevant_documents(_provider, %{"type" => type, "branch" => branch})
        when type in ["commit", "tag"] do
      repo_instance = Gitex.Git.open()
      obj = Gitex.get(branch, repo_instance)
      [obj]
    end

    def get_relevant_documents(_provider, _query), do: {:error, "Unsupported query format"}
  end
end
