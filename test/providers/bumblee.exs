# bumblebee is intended for langchain power users,
# it downloads and runs models on your local hardware
# it is only really usable on machines that have huge GPUs
# you will have to uncomment the exla XLA dependency in mix.exs
# this can potentially be a tricky build process, see https://hexdocs.pm/exla/EXLA.html

defmodule LangChain.Providers.BumblebeeTest do
  @moduledoc """
  test replicate LLMs
  """
  use ExUnit.Case
  alias LangChain.LanguageModelProtocol
  alias LangChain.Providers.Bumblebee.LanguageModel
  require Logger

  @model %LanguageModel{}

  @gpt2 %LanguageModel{
    model_name: "gpt2"
  }

  @bert %LanguageModel{
    model_name: "distilbert-base-uncased"
  }

  test "prepare_input tests" do
    # Prepare the inputs
    chat_binary = "Hello, world!"

    chat_list = [
      %{text: "Hello, world!", role: "assistant"},
      %{text: "How are you?", role: "user"}
    ]

    # Test the :for_masked_language_modeling with binary input
    result =
      LangChain.Providers.Bumblebee.prepare_input(:for_masked_language_modeling, chat_binary)

    assert result == chat_binary, "Failed :for_masked_language_modeling with binary input"

    # Test the :for_masked_language_modeling with list input
    result = LangChain.Providers.Bumblebee.prepare_input(:for_masked_language_modeling, chat_list)

    assert result == "Hello, world!\nHow are you?",
           "Failed :for_masked_language_modeling with list input"

    # Test the :for_causal_language_modeling with binary input
    result =
      LangChain.Providers.Bumblebee.prepare_input(:for_causal_language_modeling, chat_binary)

    assert result == chat_binary, "Failed :for_causal_language_modeling with binary input"

    # Test the :for_causal_language_modeling with list input
    result = LangChain.Providers.Bumblebee.prepare_input(:for_causal_language_modeling, chat_list)

    assert result == "Hello, world!\nHow are you?",
           "Failed :for_causal_language_modeling with list input"

    # Test the :for_conversational_language_modeling with binary input
    result =
      LangChain.Providers.Bumblebee.prepare_input(
        :for_conversational_language_modeling,
        chat_binary
      )

    assert result == %{text: chat_binary, history: []},
           "Failed :for_conversational_language_modeling with binary input"

    # Test the :for_conversational_language_modeling with list input
    result =
      LangChain.Providers.Bumblebee.prepare_input(
        :for_conversational_language_modeling,
        chat_list
      )

    expected_result = %{text: "How are you?", history: [{:generated, "Hello, world!"}]}

    assert result == expected_result,
           "Failed :for_conversational_language_modeling with list input"
  end

  describe "Bumblebee implementation of LanguageModelProtocol" do
    @tag timeout: :infinity
    test "ask/2 returns a valid response to binary input" do
      prompt = "What time is it now?"
      response = LanguageModelProtocol.ask(@model, prompt)
      Logger.debug(response)
      assert is_binary(response)

      response2 = LanguageModelProtocol.ask(@gpt2, "Fourscore and seven years ago")
      Logger.debug(response2)
      assert is_binary(response2)
    end

    # @tag timeout: :infinity
    # test "ask/2 returns a valid response to list input" do
    #   msgs = [
    #     %{text: "Write a sentence containing the word *grue*.", role: "user"},
    #     %{text: "Include a reference to the Dead Mountaineer's Hotel."}
    #   ]

    #   response = LanguageModelProtocol.ask(@model, msgs)
    #   Logger.debug(response)
    #   assert is_binary(response)

    #   response2 = LanguageModelProtocol.ask(@gpt2, msgs)
    #   Logger.debug(response2)
    #   assert is_binary(response2)
    # end

    # @tag timeout: :infinity
    # test "ask/2 for embedders" do
    #   # should return a warning string because it doesn't have the [MASK] token in the string
    #   response2 = LanguageModelProtocol.ask(@bert, "I will become floats")
    #   Logger.debug(response2)
    #   assert is_binary(response2)

    #   response4 = LanguageModelProtocol.ask(@bert, "I am become [MASK],the Destroyer of Worlds ")
    #   Logger.debug(response4)
    #   assert is_binary(response4)

    #   bertmsgs = [
    #     %{text: "Write a sentence containing the word *grue*.", role: "user"},
    #     %{text: "Include a reference to the Dead Mountaineer's [MASK]."}
    #   ]

    #   response3 = LanguageModelProtocol.ask(@bert, bertmsgs)
    #   Logger.debug(response3)
    #   assert is_binary(response3)
    # end
  end

  # describe "Bumblebee.Embedder implementation of EmbedderProtocol" do
  #   #   setup do
  #   #     embedder_bumblebee = %LangChain.Providers.Bumblebee.Embedder{
  #   #       model_name: "sentence-transformers/all-MiniLM-L6-v2"
  #   #     }

  #   #     {:ok, embedder: embedder_bumblebee}
  #   #   end

  #   #   test "embed_query/2 returns a valid response", %{embedder: embedder_bumblebee} do
  #   #     prompt = "What time is it now?"
  #   #     {:ok, response} = LangChain.EmbedderProtocol.embed_query(embedder_bumblebee, prompt)

  #   #     IO.inspect(response)
  #   #     # make sure it's a list of vectors
  #   #     assert is_list(response)
  #   #     assert length(response) > 0
  #   #     assert is_list(Enum.at(response, 0))
  #   #   end

  #   test "embed_documents/2 returns a valid response", %{embedder: embedder_bumblebee} do
  #     {:ok, response} =
  #       LangChain.EmbedderProtocol.embed_documents(embedder_bumblebee, [
  #         "What time is it now?",
  #         "Fourscore and seven years ago"
  #       ])

  #     # make sure it's a list of vectors
  #     assert is_list(response)
  #     assert length(response) > 0
  #     assert is_list(Enum.at(response, 0))
  #   end
  # end
end
