# first milestone: project can document itself
defmodule SelfDocumenting do
  use ExUnit.Case

  alias LangChain.TextSplitter
  alias LangChain.TextSplitter.Character

  alias LangChain.Retriever
  alias LangChain.Retriever.FileSystemProvider

  alias LangChain.EmbedderProtocol
  alias LangChain.LanguageModelProtocol
  alias LangChain.Providers.Huggingface.Embedder
  alias LangChain.Providers.Huggingface.LanguageModel

  @model %LanguageModel{
    model_name: "gpt2"
  }
  @ms_gpt_model %LanguageModel{
    model_name: "microsoft/DialoGPT-large"
  }
  @embedder_gpt2 %Embedder{
    # gpt2"
    model_name: "sentence-transformers/distilbert-base-nli-mean-tokens"
  }
  @embedder_ms_gpt %Embedder{
    model_name: "microsoft/DialoGPT-large"
  }

  test "turn self into text chunks" do
    # get the contents of all files under the /lib directory
    path = Path.dirname(__ENV__.file) |> Path.dirname() |> Path.dirname() |> Path.join("lib")
    query = %{path: path, recursive: true}
    file_system_reader = %FileSystemProvider{}
    project_source_code = Retriever.get_relevant_documents(file_system_reader, query)
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
     # get the contents of all files under the /lib directory
    path = Path.dirname(__ENV__.file) |> Path.dirname() |> Path.dirname() |> Path.join("lib")
    query = %{path: path, recursive: true}
    file_system_reader = %FileSystemProvider{}
    project_source_code = Retriever.get_relevant_documents(file_system_reader, query)
    # now split them into chunks and with the newline character as the separator
    splitter = %Character{
      embedder_name: "gpt2",
      chunk_size: 768,
      chunk_overlap: 200,
      separator: "\r\n"
    }
    chunks = TextSplitter.split_strings(splitter, project_source_code)
    EmbedderProtocol.embed_documents(@embedder_gpt2, [
      "What time is it now?",
      "Fourscore and seven years ago"
    ]) |> IO.inspect() #chunks
  end
end
