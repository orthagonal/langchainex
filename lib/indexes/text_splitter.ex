defmodule LangChain.TextSplitterConfig do

  defstruct separator: "", chunk_size: 0, chunk_overlap: 0

  # @type t :: %TextSplitterConfig{
  #         separator: String.t(),
  #         chunk_size: non_neg_integer(),
  #         chunk_overlap: non_neg_integer()
  #       }

end


defmodule LangChain.TextSplitter do
  alias LangChain.TextSplitterConfig

  def split_strings(strings, %TextSplitterConfig{} = config) do
    Enum.map(strings, fn string ->
      split_text(string, config.chunk_size, config.chunk_overlap, config.separator)
    end)
  end

  defp split_text(text, chunk_size, chunk_overlap, separator) do
    text_length = String.length(text)

    0..(text_length - 1)
    |> Stream.map(fn i -> i * (chunk_size - chunk_overlap) end)
    |> Stream.take_while(fn start_index -> start_index < text_length end)
    |> Enum.map(fn start_index ->
      end_index = min(start_index + chunk_size, text_length)
      chunk = String.slice(text, start_index, end_index)
      String.split(chunk, separator)
    end)
  end
end
