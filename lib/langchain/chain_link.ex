defmodule LangChain.ChainLink do
  @moduledoc """
  an individual chain_link in a language chain
  when called, a chainlink will
  1. fill in and submit an input prompt, then
  2. add the entire response to the responses list
  3. parse the response with the output_parser
  4. store any output
"""

  @derive Jason.Encoder
  defstruct [
    name: "Void",
    input: %LangChain.Chat{},
    output_parser: &LangChain.ChainLink.no_parse/2, # takes in the ChainLink and the list of all responses
    # from the model, pass your own output_parser to parse the output of your chat interactions
    raw_responses: [],  # the actual response returned by the model
    output: %{},  # output should be a map of %{ variable: value } produced by output_parser
    errors: []  # list of errors that occurred during evaluation
  ]

  @doc """
  calls the chain_link, filling in the input prompt and parsing the output
  """
  def call(chain_link, previousValues \\ %{}) do
    {:ok, evaluatedTemplates } = LangChain.Chat.format(chain_link.input, previousValues)
    # extract just the role and text fields from each prompt
    modelInputs = Enum.map(evaluatedTemplates, fn evaluatedTemplate -> Map.take(evaluatedTemplate, [:role, :text]) end)
    case LangChain.LLM.chat(chain_link.input.llm, modelInputs) do
      {:ok, response} ->
        chain_link.output_parser.(chain_link, response)
      {:error, reason} ->
        IO.inspect reason
        chain_link |> Map.put(:errors, [reason])
    end
  end

  @doc """
  you can define your own parser functions, but this is the default
  the output of the ChainLink will be used as variables in the next link
  by default the simple text response goes in the :text key
  """
  defp no_parse(chain_link, outputs \\ []) do
    %{
      chain_link |
      raw_responses: outputs,
      output: %{ text: outputs |> List.first |> Map.get(:text) }
    }
  end
end
