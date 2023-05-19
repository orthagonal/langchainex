defmodule LangChain.LLMTest do
  @moduledoc """
  test LLM
  """
  use ExUnit.Case, async: true

  alias LangChain.LLM
  alias LangChain.Providers.OpenAI

  setup do
    openai = %LangChain.Providers.OpenAI.LanguageModel{}
    {:ok, pid} = LLM.start_link(provider: openai)
    {:ok, pid: pid}
  end

  test "ask/2 returns a response from the language model", %{pid: pid} do
    result =
      LLM.call(pid, "Translate the following English text to French: 'Hello, how are you?'")

    Process.sleep(10_000)
    # IO.inspect(result)
    # assert {:ok, response} = result
    # assert is_binary(response)
  end
end
