defmodule LangChain.Providers.HuggingfaceTest do
  @moduledoc """
  test replicate LLMs
  """
  use ExUnit.Case
  alias LangChain.EmbedderProtocol
  alias LangChain.LanguageModelProtocol
  alias LangChain.Providers.Huggingface.Embedder
  alias LangChain.Providers.Huggingface.LanguageModel
  require Logger

  @model %LanguageModel{
    model_name: "t5-base"
  }
  @ms_gpt_model %LanguageModel{
    model_name: "microsoft/DialoGPT-large"
    # model_name: "TheBloke/vicuna-13B-1.1-HF"
  }

  @embedder_gpt2 %Embedder{
    # model_name: "gpt2"
    model_name: "sentence-transformers/distilbert-base-nli-mean-tokens"
  }
  @embedder_ms_gpt %Embedder{
    model_name: "microsoft/DialoGPT-large"
  }

  describe "Huggingface.LanguageModel implementation of LanguageModelProtocol" do
    #   test "call/2 returns a valid response" do
    #     prompt = "What time is it now?"
    #     response = LanguageModelProtocol.call(@ms_gpt_model, prompt)
    #     Logger.debug(response)
    #     assert String.length(response) > 0

    #     response2 = LanguageModelProtocol.call(@model, "Fourscore and seven years ago")
    #     Logger.debug(response2)
    #   end

    test "chat/2 returns a valid response" do
      msgs = [
        %{text: "Write a sentence containing the word *grue*.", role: "user"},
        %{text: "Include a reference to the Dead Mountaineers Hotel."}
      ]

      response = LanguageModelProtocol.chat(@ms_gpt_model, msgs)

      Logger.debug(response)
      assert is_list(response)
      assert length(response) > 0
    end
  end

  # describe "Huggingface.Embedder implementation of EmbedderProtocol" do
  #   # test "embed_query/2 returns a valid response" do
  #   #   prompt = "What time is it now?"
  #   #   response = EmbedderProtocol.embed_query(@embedder_gpt2, prompt)
  #   #   Logger.debug(response)
  #   #   # make sure it's a list of vectors
  #   #   # assert is_list(response)
  #   #   # assert length(response) > 0
  #   #   # assert is_list(Enum.at(response, 0))
  #   # end

  #   test "embed_documents/2 returns a valid response" do
  #     response =
  #       EmbedderProtocol.embed_documents(@embedder_gpt2, [
  #         "What time is it now?",
  #         "Fourscore and seven years ago"
  #       ])

  #     Logger.debug(response)
  #     #     # make sure it's a list of vectors
  #     #     assert is_list(response)
  #     #     assert length(response) > 0
  #     #     assert is_list(Enum.at(response, 0))
  #   end
  # end
end
