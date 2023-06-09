# credo:disable-for-this-file
defmodule LangChain.Retriever.GitTest do
  use ExUnit.Case

  @gitex %LangChain.Retriever.Git{}


  describe "get_relevant_documents/2" do
    test "returns blob from a given path" do
      query = %{"type" => "blob", "branch" => "primary", "path" => "/mix.exs"}
      IO.inspect query
      result = LangChain.Retriever.get_relevant_documents(@gitex, query)
      IO.inspect result
    end

    test "returns tree from a given path" do
      query = %{"type" => "tree", "branch" => "primary", "path" => "/lib"}
      result = LangChain.Retriever.get_relevant_documents(@gitex, query)
      IO.inspect result
    end

    test "returns commit from a given branch" do
      query = %{"type" => "commit", "branch" => "primary"}
      response = LangChain.Retriever.get_relevant_documents(@gitex, query)
      IO.inspect response
    end

    test "returns an error for an invalid query" do
      query = %{"type" => "invalid_type", "branch" => "primary", "repo" => "test_repo"}
      assert {:error, _} = LangChain.Retriever.get_relevant_documents(@gitex, query)
    end
  end
end
