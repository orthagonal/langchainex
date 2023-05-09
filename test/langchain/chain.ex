defmodule LangChain.ChainTest do
  @moduledoc """
  Tests for LangChain.Chain
  """
  use ExUnit.Case
  alias LangChain.{LLM, Chat, Chain, ChainLink, PromptTemplate}


  # takes list of all outputs and the ChainLink that evaluated them
  # returns the new state of the ChainLink
  def temp_parser(chain_link, outputs) do
    output = %{
      outputs: outputs,
      text: outputs,
      processed_by: chain_link.name
    }

    %LangChain.ChainLink{
      chain_link
      | raw_responses: outputs,
        output: output
    }
  end

  defp temp_parser2(chain_link, outputs) do
    %{
      chain_link
      | raw_responses: outputs,
        output: %{
          enchanter_text: outputs,
          processed_by: chain_link.name,
          # match any case
          contains_zork: Regex.match?(~r/zork/i, outputs)
        }
    }
  end

  defp temp_parser3(chain_link, outputs) do
    IO.puts "temp parser calledwith"
    IO.inspect outputs
    IO.inspect(chain_link)
    %{
      chain_link
      | raw_responses: outputs,
        output: %{
          duration_text: outputs,# |> List.first() |> Map.get(:text),
          processed_by: chain_link.name
        }
    }
  end

  test "Test individual Link with raw string" do
    link = %LangChain.ChainLink{
      input:  "Who wrote the novel Solaris?",
      name: "enchanter",
      output_parser: &temp_parser/2
    }

    # Set up the OpenAI LLM provider
    openai_provider = %LangChain.Providers.OpenAI{
      model_name: "text-ada-001",
      max_tokens: 25,
      temperature: 0.5,
      n: 1
    }

    # # Start the LLM GenServer with the OpenAI provider
    {:ok, llm_pid} = LangChain.LLM.start_link(provider: openai_provider)

    # When we evaluate a chain link, we get a new chain link with the output variables
    new_link_state = LangChain.ChainLink.call(link, llm_pid, %{spell: "frotz"})

    # Make sure it's the right link and the output has the right keys
    assert Map.keys(new_link_state.output) == [:text]
    assert Map.keys(new_link_state) == [:__struct__, :errors, :input, :name, :output, :output_parser, :process_with, :processed_by, :raw_responses]
  end

  test "Test individual Link with prompttemplate" do
    link = %LangChain.ChainLink{
      input:  %LangChain.PromptTemplate{template: "memorize <%= spell %>"},
      name: "enchanter",
      output_parser: &temp_parser/2
    }

    # Set up the OpenAI LLM provider
    openai_provider = %LangChain.Providers.OpenAI{
      model_name: "text-ada-001",
      max_tokens: 25,
      temperature: 0.5,
      n: 1
    }

    # # Start the LLM GenServer with the OpenAI provider
    {:ok, llm_pid} = LangChain.LLM.start_link(provider: openai_provider)

    # When we evaluate a chain link, we get a new chain link with the output variables
    new_link_state = LangChain.ChainLink.call(link, llm_pid, %{spell: "frotz"})

    # # Make sure it's the right link and the output has the right keys
    # assert "enchanter" == new_link_state.output.processed_by
    assert Map.keys(new_link_state.output) == [:outputs, :processed_by, :text]
  end

  test "Test Chain with multiple ChainLinks" do

    chain = %Chain{
      links: [
        %LangChain.ChainLink{
          input:  %LangChain.PromptTemplate{ template: "I have memorized the spell <%= spell %>"},
          name: "enchanter",
          output_parser: &temp_parser/2
        },
        %LangChain.ChainLink{
          input:  %LangChain.PromptTemplate{ template: "I then cast <%= spell %> on the brass lantern.  What game am I playing?" },
          name: "sorcerer",
          output_parser: &temp_parser2/2
        },
        %LangChain.ChainLink{
          input:  %LangChain.PromptTemplate{ template: "This LLM <%= if contains_zork do \"is\" else \"is not\" end %> cool." },
          name: "spellbreaker",
          output_parser: &temp_parser/2
        }
      ]
    }

    # Set up the OpenAI LLM provider
    openai_provider = %LangChain.Providers.OpenAI{
      model_name: "gpt-3.5-turbo",
      max_tokens: 25,
      temperature: 0.5,
      n: 1
    }

    # Start the LLM GenServer with the OpenAI provider
    {:ok, llm_pid} = LangChain.LLM.start_link(provider: openai_provider)

    # Call the Chain with initial values
    result = Chain.call(chain, llm_pid, %{spell: "frotz"})

    # Check if the output contains keys from both links
    assert Map.keys(result) ==  [:contains_zork, :enchanter_text, :outputs, :processed_by, :spell, :text]
  end
end
