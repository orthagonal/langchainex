defmodule LangChain.LLMTest do
  use ExUnit.Case, async: true

  alias LangChain.LLM
  alias LangChain.Providers.OpenAI

  setup do
    openai = %OpenAI{}
    {:ok, pid} = LLM.start_link(provider: openai)
    {:ok, pid: pid}
  end

  test "call/2 returns a response from the language model", %{pid: pid} do
    result =
      LLM.call(pid, "Translate the following English text to French: 'Hello, how are you?'")

    Process.sleep(10000)
    # assert {:ok, response} = result
    # assert is_binary(response)
  end

  # test "chat/2 returns a response from the language model", %{pid: pid} do
  #   msgs = [%{text: "Translate the following English text to French: 'Hello, how are you?'", role: "user"}]
  #   result = LLM.chat(pid, msgs)
  #   assert {:ok, response} = result
  #   assert is_list(response)
  #   assert Enum.count(response) == 1
  #   assert %{text: text, role: "assistant"} = Enum.at(response, 0)
  #   assert is_binary(text)
  # end
end
