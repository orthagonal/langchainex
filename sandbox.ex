defmodule Testing do


  def split_strings(strings, config) do
    Enum.map(strings, fn string ->
      split_text(string, config.chunk_size, config.chunk_overlap, config.separator)
    end)
  end

  defp split_text(text, chunk_size, chunk_overlap, separator) do
    text_length = String.length(text)

    0..(text_length - 1)

    strm = Stream.map(0..(text_length - 1),  fn i -> i * (chunk_size - chunk_overlap) end  )
    # strm2 = Stream.take_while(strm, fn start_index -> start_index < text_length end)
    IO.inspect(strm)
    Enum.map(strm, fn i -> i end) |> IO.inspect()

    # |> Stream.map(fn i -> i * (chunk_size - chunk_overlap) end)
    # |> Stream.take_while(fn start_index -> start_index < text_length end)
    # |> Enum.map(fn start_index ->
      #   end_index = min(start_index + chunk_size, text_length)
      #   chunk = String.slice(text, start_index, end_index)
      #   String.split(chunk, separator)
      # end)
    end
  end

page_content=["Madam Speaker, Madam Vice President, our First Lady and Second Gentleman. Members of Congress and the Cabinet. Justices of the Supreme Court. My fellow Americans.  \n\nLast year COVID-19 kept us apart. This year we are finally together again. \n\nTonight, we meet as Democrats Republicans and Independents. But most importantly as Americans. \n\nWith a duty to one another to the American people to the Constitution. \n\nAnd with an unwavering resolve that freedom will always triumph over tyranny. \n\nSix days ago, Russia’s Vladimir Putin sought to shake the foundations of the free world thinking he could make it bend to his menacing ways. But he badly miscalculated. \n\nHe thought he could roll into Ukraine and the world would roll over. Instead he met a wall of strength he never imagined. \n\nHe met the Ukrainian people. \n\nFrom President Zelenskyy to every Ukrainian, their fearlessness, their courage, their determination, inspires the world."]
config = %{separator: "\n\n", chunk_size: 10, chunk_overlap: 2}

Testing.split_strings(page_content, config) |> IO.inspect(label: "Result")
