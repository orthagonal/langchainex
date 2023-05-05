defmodule LangChain.ChainTest do
  use ExUnit.Case
  alias LangChain.{LLM, Chat, Chain, ChainLink, PromptTemplate}

  # takes list of all outputs and the ChainLink that evaluated them
  # returns the new state of the ChainLink
  def tempParser(chainLink, outputs) do
    output = %{
      outputs: outputs,
      text: outputs |> List.first() |> Map.get(:text),
      processed_by: chainLink.name
    }

    %LangChain.ChainLink{
      chainLink
      | rawResponses: outputs,
        output: output
    }
  end

  test "Test individual Link" do
    chat =
      LangChain.Chat.addPromptTemplates(%LangChain.Chat{}, [
        %{role: "user", prompt: %LangChain.PromptTemplate{template: "memorize <%= spell %>"}},
        %{
          role: "user",
          prompt: %LangChain.PromptTemplate{template: "cast <%= spell %> on lantern"}
        }
      ])

    link = %LangChain.ChainLink{
      name: "enchanter",
      input: chat,
      outputParser: &tempParser/2
    }

    # when we evaluate a chain link, we get a new chain link with the output variables
    newLinkState = LangChain.ChainLink.call(link, %{spell: "frotz"})
    # make sure it's the right link and the output has the right keys
    assert "enchanter" == newLinkState.output.processed_by
    assert Map.keys(newLinkState.output) == [:outputs, :processed_by, :text]
    # the AI's response won't be the same every time!
    IO.inspect(newLinkState.output.text)
  end

  test "Test Chain with multiple ChainLinks" do
    chat1 =
      Chat.addPromptTemplates(%Chat{}, [
        %{role: "user", prompt: %PromptTemplate{template: "memorize <%= spell %>"}},
        %{role: "user", prompt: %PromptTemplate{template: "cast <%= spell %> on lantern"}}
      ])

    chat2 =
      Chat.addPromptTemplates(%Chat{}, [
        %{
          role: "user",
          prompt: %PromptTemplate{
            template: "This LLM <%= if contains_zork do \"is\" else \"is not\" end %> cool."
          }
        }
      ])

    link1 = %ChainLink{
      name: "enchanter",
      input: chat1,
      outputParser: &tempParser1/2
    }

    link2 = %ChainLink{
      name: "duration",
      input: chat2,
      outputParser: &tempParser2/2
    }

    chain = %Chain{
      links: [link1, link2]
    }

    # Call the Chain with initial values
    result = Chain.call(chain, %{spell: "frotz"})

    # Check if the output contains keys from both links
    assert Map.keys(result) == [
             :contains_zork,
             :duration_text,
             :enchanter_text,
             :processed_by,
             :spell
           ]

    # # Inspect the text outputs from both links (AI responses won't be the same every time)
    IO.inspect(result[:enchanter_text])
    IO.inspect(result[:duration_text])
  end

  defp tempParser1(chain_link, outputs) do
    %{
      chain_link
      | rawResponses: outputs,
        output: %{
          enchanter_text: outputs |> List.first() |> Map.get(:text),
          processed_by: chain_link.name,
          # match any case
          contains_zork: Regex.match?(~r/zork/i, outputs |> List.first() |> Map.get(:text))
        }
    }
  end

  defp tempParser2(chain_link, outputs) do
    %{
      chain_link
      | rawResponses: outputs,
        output: %{
          duration_text: outputs |> List.first() |> Map.get(:text),
          processed_by: chain_link.name
        }
    }
  end
end
