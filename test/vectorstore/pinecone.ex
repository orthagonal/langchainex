defmodule LangChain.VectorStore.PineconeProviderTest do
  use ExUnit.Case, async: true
  alias LangChain.VectorStore.PineconeProvider

  describe "add_vectors/2" do
    test "successfully adds vectors and returns upserted count" do
      # make 3 vectors of size 1536 each, since the openai davicini model uses that size vector
      vectors = Enum.map(1..3, fn _ ->
        Enum.map(1..1536, fn _ -> :rand.uniform() end)
      end)
      result = PineconeProvider.add_vectors(:pinecone, vectors)
      IO.inspect result
      assert {:ok, 3} == result
    end
  end
end
