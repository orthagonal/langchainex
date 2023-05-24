# first milestone: project can document itself
defmodule SelfDocumenting do
  use ExUnit.Case

  alias LangChain.LanguageModelProtocol

  alias LangChain.TextSplitter
  alias LangChain.TextSplitter.Character

  alias LangChain.Retriever
  alias LangChain.Retriever.FileSystemProvider

  # alias LangChain.EmbedderProtocol
  # alias LangChain.Providers.Huggingface.Embedder
  # alias LangChain.Providers.Huggingface.LanguageModel
  alias LangChain.LanguageModelProtocol

  # test "turn self into text chunks" do
  #   # get the contents of all files under the /lib directory
  #   path = Path.dirname(__ENV__.file) |> Path.dirname() |> Path.dirname() |> Path.join("lib")
  #   query = %{path: path, recursive: true}
  #   file_system_reader = %FileSystemProvider{}
  #   project_source_code = Retriever.get_relevant_documents(file_system_reader, query)
  #   # now split them into chunks and with the newline character as the separator
  #   splitter = %Character{
  #     embedder_name: "gpt2",
  #     chunk_size: 1000,
  #     chunk_overlap: 200,
  #     separator: "\r\n"
  #   }
  #   chunks = TextSplitter.split_strings(splitter, project_source_code)
  #   IO.inspect(chunks)
  # end

  test "document it the langchain way" do
    path = Path.dirname(__ENV__.file) |> Path.dirname() |> Path.dirname() |> Path.join("lib")
    query = %{path: path, recursive: true}
    file_system_reader = %FileSystemProvider{}
    project_source_code = Retriever.get_relevant_documents(file_system_reader, query)

    splitter = %Character{
      embedder_name: "gpt2",
      chunk_size: 1000,
      chunk_overlap: 200,
      separator: "\r\n"
    }

    chunks = TextSplitter.split_strings(splitter, project_source_code)

    model = {%LangChain.Providers.OpenAI.LanguageModel{}, %{}}

    chunk = chunks |> Enum.at(0)
    acc = ""
    result = LanguageModelProtocol.ask(model, "
    I am building a documentation markdown for my GitHub project.
    This is the markdown I have written so far:

    #{acc}

    Now examine this chunk of code in light of the previous documentation:

    #{chunk}

    and write out the entire documentation.
    ")
    IO.inspect(result)

    # chunks
    # |> Enum.reduce('', chunks, fn chunk, acc ->
    # result = LanguageModelProtocol.ask(model, "
    #   I am building a documentation markdown for my GitHub project.
    #   This is what I have written so far:

    #   '#{acc}

    #   Now examine this chunk of code in light of the previous documentation:

    #   #{chunk}

    #   and write out the entire documentation.
    #   ")
    # IO.inspect(result)
    #   result
    # end)
  end
end
