# """
# A Protocol for splitting text up (by character, word, sentence, semantic unit, etc
# and then 'chunking' it into smaller pieces so that it can be vectorized
# and fed to a neural network)
# """
defprotocol LangChain.TextSplitter do
  def split_strings(splitter, documents)
  def split_text(splitter, text)
end

defmodule LangChain.TextSplitter.Character do
  @moduledoc """
  simple splitter that splits strings on a special character,
  like '\n' or '.'
  """

  # embedder_name is optional hint about what model the chunks are intended for
  defstruct embedder_name: "gpt2",
            separator: "\n\n",
            # mandatory, the max size of the chunks we want to split the text into
            chunk_size: 10,
            chunk_overlap: 0

  defimpl LangChain.TextSplitter do
    def split_strings(splitter, documents) do
      Enum.map(documents, &split_text(splitter, &1))
    end

    def split_text(splitter, text) do
      text
      |> String.graphemes()
      |> Enum.chunk_every(splitter.chunk_size, splitter.chunk_overlap, :discard)
      |> Enum.map(&Enum.join(&1))
    end
  end
end
