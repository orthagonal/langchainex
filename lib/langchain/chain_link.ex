defmodule LangChain.ChainLink do
  @moduledoc """
  an individual chainLink in a language chain
  when called, a chainlink will
  1. fill in and submit an input prompt, then
  2. add the entire response to the responses list
  3. parse the response with the outputParser
  4. store any output
"""

  @derive Jason.Encoder
  defstruct [
    name: "Void",
    input: %LangChain.Chat{},
    outputParser: &LangChain.ChainLink.noParse/2, # takes in the ChainLink and the list of all responses
    # from the model, pass your own outputParser to parse the output of your chat interactions
    rawResponses: [],  # the actual response returned by the model
    output: %{},  # output should be a map of %{ variable: value } produced by outputParser
    errors: []  # list of errors that occurred during evaluation
  ]

  def call(chainLink, previousValues \\ %{}) do
    @doc """
    calls the chainLink, filling in the input prompt and parsing the output
    """
    {:ok, evaluatedTemplates } = LangChain.Chat.format(chainLink.input, previousValues)
    # extract just the role and text fields from each prompt
    modelInputs = Enum.map(evaluatedTemplates, fn evaluatedTemplate -> Map.take(evaluatedTemplate, [:role, :text]) end)
    case LangChain.LLM.chat(chainLink.input.llm, modelInputs) do
      {:ok, response} ->
        chainLink.outputParser.(chainLink, response)
      {:error, reason} ->
        IO.inspect reason
        chainLink |> Map.put(:errors, [reason])
    end
  end

  # you can define your own parser functions, but this is the default
  # the output of the ChainLink will be used as variables in the next link
  # by default the simple text response goes in the :text key
  defp noParse(chainLink, outputs \\ []) do
    %{
      chainLink |
      rawResponses: outputs,
      output: %{ text: outputs |> List.first |> Map.get(:text) }
    }
  end
end
