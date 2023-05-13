defmodule CharacterTextSplitterTest do
  use ExUnit.Case
  alias LangChain.TextSplitter
  alias LangChain.TextSplitter.Character

  @page_content [
    "Madam Speaker, Madam Vice President, our First Lady and Second Gentleman. Members of Congress and the Cabinet. Justices of the Supreme Court. My fellow Americans.  \n\nLast year COVID-19 kept us apart. This year we are finally together again. \n\nTonight, we meet as Democrats Republicans and Independents. But most importantly as Americans. \n\nWith a duty to one another to the American people to the Constitution. \n\nAnd with an unwavering resolve that freedom will always triumph over tyranny. \n\nSix days ago, Russia’s Vladimir Putin sought to shake the foundations of the free world thinking he could make it bend to his menacing ways. But he badly miscalculated. \n\nHe thought he could roll into Ukraine and the world would roll over. Instead he met a wall of strength he never imagined. \n\nHe met the Ukrainian people. \n\nFrom President Zelenskyy to every Ukrainian, their fearlessness, their courage, their determination, inspires the world."
  ]

  setup do
    splitter = %Character{
      embedder_name: "gpt2",
      chunk_size: 10,
      chunk_overlap: 2
    }

    {:ok, splitter: splitter}
  end

  def verify_splitter(splitter, result) do
    # ensure result is a list
    assert is_list(result)
    # ensure all elements of result are lists
    assert Enum.all?(result, &Kernel.is_list/1)
    # ensure all chunks are strings
    assert Enum.all?(result, fn chunks -> Enum.all?(chunks, &is_binary/1) end)
    # ensure all chunks are the correct length
    # ensure at least one chunk has been split correctly
    assert Enum.any?(result, fn chunks -> Enum.any?(chunks, &String.contains?(&1, "\n")) end)
  end

  test "split_strings/1 with file path", %{splitter: splitter} do
    # get the path to *this* file
    result = TextSplitter.split_strings(splitter, @page_content)
    verify_splitter(splitter, result)
  end

  test "split_text/1 with file path", %{splitter: splitter} do
    # get the path to *this* file
    result = TextSplitter.split_text(splitter, "The Polito form is dead \n\n insect")
    verify_splitter(splitter, [result])
  end
end
