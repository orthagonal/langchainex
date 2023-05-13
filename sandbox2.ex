


  defmodule StringSplitter do
    def split_strings(strings, selector, chunk_size, chunk_overlap) do
      Stream.with_index(strings, 1)
      |> Stream.flat_map(fn {string, index} -> split_string(string, selector, chunk_size, chunk_overlap, index) end)
      |> Stream.map(&%{"chunk" => &1, "origin" => elem(&1, 1)})
      |> Enum.to_list()
    end

    def split_string(string, selector, chunk_size, chunk_overlap, index) do
      string
      |> String.split(selector, trim: true) |> IO.inspect()
      |> Stream.flat_map(&chunk_string(&1, chunk_size, chunk_overlap))
      # |> Stream.map(&{&1, index})
    end

    def chunk_string(string, chunk_size, chunk_overlap) do
      0..(String.length(string) - chunk_size)
      |> Stream.map(&String.slice(string, &1, chunk_size))
      |> Stream.chunk_every(chunk_size, chunk_overlap, :discard)
      |> Stream.concat()
    end
  end



page_content=["Madam \n\nSpeaker, Madam Vice President, our First Lady and Second Gentleman. Members of Congress and the Cabinet. Justices of the Supreme Court. My fellow Americans.  \n\nLast year COVID-19 kept us apart. This year we are finally together again. \n\nTonight, we meet as Democrats Republicans and Independents. But most importantly as Americans. \n\nWith a duty to one another to the American people to the Constitution. \n\nAnd with an unwavering resolve that freedom will always triumph over tyranny. \n\nSix days ago, Russia’s Vladimir Putin sought to shake the foundations of the free world thinking he could make it bend to his menacing ways. But he badly miscalculated. \n\nHe thought he could roll into Ukraine and the world would roll over. Instead he met a wall of strength he never imagined. \n\nHe met the Ukrainian people. \n\nFrom President Zelenskyy to every Ukrainian, their fearlessness, their courage, their determination, inspires the world."]
config = %{separator: "\n\n", chunk_size: 10, chunk_overlap: 2}
chunk_size = 10
chunk_overlap = 2

# StringSplitter.split_string(page_content, "\n\n", 50, 2, 1) |> IO.inspect(label: "Result")

Stream.map(page_content, fn string ->
  String.split(string, "\n\n", trim: true) end)
|> Enum.to_list
|> IO.inspect()
#String.length

#Stream.map(0..(String.length(string)), fn i -> String.slice(string, i, chunk_size) end) |> Enum.to_list() |> IO.inspect()

#String.slice(string, 0, 10)
