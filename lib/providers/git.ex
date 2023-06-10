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

    def get_relevant_documents(_provider, _query) do
      {:error,
       "Invalid query. Query must include 'type', 'branch', 'path' is optional and used for 'blob' and 'tree' types."}
    end
  end
end
