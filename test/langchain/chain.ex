defmodule LangChain.ChainTest do
  use ExUnit.Case
  alias LangChain.{LLM, Chat, Chain, ChainLink, PromptTemplate}

  # takes list of all outputs and the ChainLink that evaluated them
  # returns the new state of the ChainLink
  def temp_parser(chain_link, outputs) do
    output = %{
      outputs: outputs,
<<<<<<< HEAD
      text: outputs |> List.first() |> Map.get(:text),
=======
      text: outputs |> List.first |> Map.get(:text),
>>>>>>> ec662107a4d15557c6fac5844422bd5d3660e98b
      processed_by: chain_link.name
    }

    %LangChain.ChainLink{
<<<<<<< HEAD
      chain_link
      | raw_responses: outputs,
        output: output
=======
      chain_link |
      raw_responses: outputs,
      output: output
>>>>>>> ec662107a4d15557c6fac5844422bd5d3660e98b
    }
  end

  test "Test individual Link" do
<<<<<<< HEAD
    chat =
      LangChain.Chat.add_prompt_templates(%LangChain.Chat{}, [
        %{role: "user", prompt: %LangChain.PromptTemplate{template: "memorize <%= spell %>"}},
        %{
          role: "user",
          prompt: %LangChain.PromptTemplate{template: "cast <%= spell %> on lantern"}
        }
      ])

=======
    chat = LangChain.Chat.add_prompt_templates(%LangChain.Chat{}, [
      %{role: "user", prompt: %LangChain.PromptTemplate{template: "memorize <%= spell %>"}},
      %{role: "user", prompt: %LangChain.PromptTemplate{template: "cast <%= spell %> on lantern"}},
    ])
>>>>>>> ec662107a4d15557c6fac5844422bd5d3660e98b
    link = %LangChain.ChainLink{
      name: "enchanter",
      input: chat,
      output_parser: &temp_parser/2
    }

    # when we evaluate a chain link, we get a new chain link with the output variables
    new_link_state = LangChain.ChainLink.call(link, %{spell: "frotz"})
    # make sure it's the right link and the output has the right keys
    assert "enchanter" == new_link_state.output.processed_by
    assert Map.keys(new_link_state.output) == [:outputs, :processed_by, :text]
<<<<<<< HEAD
    # the AI's response won't be the same every time!
    IO.inspect(new_link_state.output.text)
  end

  test "Test Chain with multiple ChainLinks" do
    chat1 =
      Chat.add_prompt_templates(%Chat{}, [
        %{role: "user", prompt: %PromptTemplate{template: "memorize <%= spell %>"}},
        %{role: "user", prompt: %PromptTemplate{template: "cast <%= spell %> on lantern"}}
      ])

    chat2 =
      Chat.add_prompt_templates(%Chat{}, [
        %{
          role: "user",
          prompt: %PromptTemplate{
            template: "This LLM <%= if contains_zork do \"is\" else \"is not\" end %> cool."
          }
        }
      ])
=======
    IO.inspect new_link_state.output.text # the AI's response won't be the same every time!
  end

  test "Test Chain with multiple ChainLinks" do
    chat1 = Chat.add_prompt_templates(%Chat{}, [
      %{role: "user", prompt: %PromptTemplate{template: "memorize <%= spell %>"}},
      %{role: "user", prompt: %PromptTemplate{template: "cast <%= spell %> on lantern"}},
    ])

    chat2 = Chat.add_prompt_templates(%Chat{}, [
      %{role: "user", prompt: %PromptTemplate{template: "This LLM <%= if contains_zork do \"is\" else \"is not\" end %> cool."}},
    ])
>>>>>>> ec662107a4d15557c6fac5844422bd5d3660e98b

    link1 = %ChainLink{
      name: "enchanter",
      input: chat1,
      output_parser: &temp_parser1/2
    }

    link2 = %ChainLink{
      name: "duration",
      input: chat2,
      output_parser: &temp_parser2/2
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

  defp temp_parser1(chain_link, outputs) do
    %{
<<<<<<< HEAD
      chain_link
      | raw_responses: outputs,
        output: %{
          enchanter_text: outputs |> List.first() |> Map.get(:text),
          processed_by: chain_link.name,
          # match any case
          contains_zork: Regex.match?(~r/zork/i, outputs |> List.first() |> Map.get(:text))
        }
=======
      chain_link |
      raw_responses: outputs,
      output: %{
        enchanter_text: outputs |> List.first |> Map.get(:text),
        processed_by: chain_link.name,
        # match any case
        contains_zork: Regex.match?(~r/zork/i, outputs |> List.first |> Map.get(:text))
      }
>>>>>>> ec662107a4d15557c6fac5844422bd5d3660e98b
    }
  end

  defp temp_parser2(chain_link, outputs) do
    %{
<<<<<<< HEAD
      chain_link
      | raw_responses: outputs,
        output: %{
          duration_text: outputs |> List.first() |> Map.get(:text),
          processed_by: chain_link.name
        }
=======
      chain_link |
      raw_responses: outputs,
      output: %{
        duration_text: outputs |> List.first |> Map.get(:text),
        processed_by: chain_link.name
      }
>>>>>>> ec662107a4d15557c6fac5844422bd5d3660e98b
    }
  end
end
