# bumblebee downloads and runs models on your local hardware
# it is only really usable on machines that have reasonable GPUs
# you will have to uncomment the exla XLA dependency in mix.exs
# this can potentially be a tricky build process, see https://hexdocs.pm/exla/EXLA.html

defmodule LangChain.Providers.BumblebeeTest do
  @moduledoc """
  test replicate LLMs
  """
  use ExUnit.Case
  alias LangChain.LanguageModelProtocol
  alias LangChain.Providers.Bumblebee
  require Logger

  @tag timeout: :infinity

  @model %Bumblebee{
    model_name: "gpt2"
  }

  @fb_bb_model %Bumblebee{
    model_name: "facebook/blenderbot-400M-distill"
  }

  # describe "Bumblebee implementation of LanguageModelProtocol" do
  #   test "call/2 returns a valid response" do
  #     prompt = "What time is it now?"
  #     response = LanguageModelProtocol.call(@model, prompt)
  #     Logger.debug(response)
  #     assert String.length(response) > 0

  #     response2 = LanguageModelProtocol.call(@model, "Fourscore and seven years ago")
  #     Logger.debug(response2)
  #   end

  #   test "chat/2 returns a valid response" do
  #     msgs = [
  #       %{text: "Write a sentence containing the word *grue*.", role: "user"},
  #       %{text: "Include a reference to the Dead Mountaineers Hotel."}
  #     ]

  #     response = LanguageModelProtocol.chat(@fb_bb_model, msgs)
  #     Logger.debug(response)
  #     assert is_list(response)
  #     assert length(response) > 0
  #   end
  # end

  # describe "Bumblebee.Embedder implementation of EmbedderProtocol" do
  #   setup do
  #     embedder_bumblebee = %LangChain.Providers.Bumblebee.Embedder{
  #       model_name: "sentence-transformers/all-MiniLM-L6-v2"
  #     }

  #     {:ok, embedder: embedder_bumblebee}
  #   end

  #   test "embed_query/2 returns a valid response", %{embedder: embedder_bumblebee} do
  #     prompt = "What time is it now?"
  #     {:ok, response} = LangChain.EmbedderProtocol.embed_query(embedder_bumblebee, prompt)

  #     IO.inspect(response)
  #     # make sure it's a list of vectors
  #     assert is_list(response)
  #     assert length(response) > 0
  #     assert is_list(Enum.at(response, 0))
  #   end

    test "embed_documents/2 returns a valid response", %{embedder: embedder_bumblebee} do
      {:ok, response} =
        LangChain.EmbedderProtocol.embed_documents(embedder_bumblebee, [
          "What time is it now?",
          "Fourscore and seven years ago"
        ])

      # make sure it's a list of vectors
      assert is_list(response)
      assert length(response) > 0
      assert is_list(Enum.at(response, 0))
    end
  end
end
