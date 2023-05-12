defmodule LangChain.Providers.ReplicateTest do
  @moduledoc """
  test replicate LLMs
  """
  use ExUnit.Case
  alias LangChain.LanguageModelProtocol
  alias LangChain.Providers.Replicate
  require Logger

  @model %Replicate{
    version: "5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa"
  }

  @vicuna_13_b %Replicate{
    version: "a68b84083b703ab3d5fbf31b6e25f16be2988e4c3e21fe79c2ff1c18b99e61c1"
  }

  @stablelm_tuned_alpha_7b %Replicate{
    version: "c49dae362cbaecd2ceabb5bd34fdb68413c4ff775111fea065d259d577757beb"
  }

  @dolly_v2_12b %Replicate{
    version: "ef0e1aefc61f8e096ebe4db6b2bacc297daf2ef6899f0f7e001ec445893500e5"
  }

  @gpt_j_6b %Replicate{
    version: "b3546aeec6c9891f0dd9929c2d3bedbf013c12e02e7dd0346af09c37e008c827"
  }

  describe "Replicate implementation of LanguageModelProtocol" do
    test "call/2 returns a valid response" do
      prompt = "Write a sentence containing the word *grue*."
      response = LanguageModelProtocol.call(@model, prompt)
      Logger.debug(response)
      assert String.length(response) > 0
      assert String.contains?(response, "grue")

      response2 = LanguageModelProtocol.call(@dolly_v2_12b, prompt)
      Logger.debug(response2)
    end

    # test "chat/2 returns a valid response" do
    #   msgs = [
    #     %{text: "Write a sentence containing the word *grue*.", role: "user"},
    #     %{text: "Include a reference to the Dead Mountaineers Hotel."}
    #   ]

    #   response = LanguageModelProtocol.chat(@dolly_v2_12b, msgs)
    #   Logger.debug(response)
    #   assert is_list(response)
    #   assert length(response) > 0
    # end
  end
end
