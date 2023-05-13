# first milestone: project can document itself
defmodule SelfDocumenting do
  use ExUnit.Case

  alias LangChain.TextSplitter
  alias LangChain.TextSplitter.Character

  alias LangChain.Retriever
  alias LangChain.Retriever.FileSystemProvider

  test "turn self into text chunks" do
    # get the contents of all files under the /lib directory
    path = Path.dirname(__ENV__.file) |> Path.dirname() |> Path.dirname() |> Path.join("lib")
    query = %{path: path, recursive: true}
    fileSystemReader = %FileSystemProvider{}
    project_source_code = Retriever.get_relevant_documents(fileSystemReader, query)
    # now split them into chunks and with the newline character as the separator
    splitter = %Character{
      embedder_name: "gpt2",
      chunk_size: 1000,
      chunk_overlap: 200,
      separator: "\r\n"
    }

    chunks = TextSplitter.split_strings(splitter, project_source_code)
  end

  test "turn self into text chunks and then embed them" do
  end
end
