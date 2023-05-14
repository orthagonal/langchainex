# first milestone: project can document itself
defmodule SelfDocumenting do
  use ExUnit.Case

  alias LangChain.LanguageModelProtocol

  alias LangChain.TextSplitter
  alias LangChain.TextSplitter.Character

  alias LangChain.Retriever
  alias LangChain.Retriever.FileSystemProvider

  alias LangChain.EmbedderProtocol
  alias LangChain.Providers.Huggingface.Embedder
  alias LangChain.Providers.Huggingface.LanguageModel

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

  # test "turn self into text chunks and then embed them" do
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
  #   # IO.inspect(chunks)

  #   response =
  #     EmbedderProtocol.embed_documents(
  #       %Embedder{
  #         # model_name: "gpt2"
  #         model_name: "sentence-transformers/distilbert-base-nli-mean-tokens"
  #       },
  #       chunks |> Enum.take(10)
  #     )

  #   Logger.debug(response)
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

    # get the first chunk
    chunk1 = Enum.at(chunks, 0)

    # turn source code into a list of messages
    src_as_msgs =
      Enum.map(chunk1, fn chunk ->
        %{
          text: chunk,
          role: "user"
        }
      end)

    model = %LanguageModel{
      model_name: "google/flan-t5-xl"
      # model_name: "microsoft/DialoGPT-large"
    }

    IO.puts("asking the question:")

    question =
      src_as_msgs
      |> Enum.take(1)
      |> Enum.concat([
        %{
          text: "Summarize the code above",
          role: "user"
        }
      ])

    # IO.inspect(question)
    response = LanguageModelProtocol.chat(model, question)
    IO.puts(">>>>>>>>>>>>>>>>>>>>>>>>>>")
    IO.inspect(response)
    Process.sleep(5_000)
  end
end
