defmodule LangChain.SchemaChain do
  @moduledoc """
  Use this when you want to extract formatted data from natural-language text, SchemaChain is basically
  a special form of QueryChain.
  SchemaChain is a wrapper around a special type of Chain that requires 'inputSchema' and 'inputText' in its
  inputVariables and combines it with an outputParser.
  Once you define that chain, you can 'ask' the SchemaChain to run the chain and return the
  formatted output in any form.
  """

  @derive Jason.Encoder
  defstruct [
    chain: %LangChain.Chain{},
    inputSchema: "",
    outputParser: &LangChain.SchemaChain.noParse/1
  ]

  def new(chain, inputSchema, outputParser \\ &LangChain.SchemaChain.noParse/1) do
    %LangChain.SchemaChain{
      chain: chain,
      inputSchema: inputSchema,
      outputParser: outputParser
    }
  end

  def ask(schema_chain, input_text) do
    # Fill in the inputText and inputSchema values and run the Chain
    inputVariables = %{
      inputText: input_text,
      inputSchema: schema_chain.inputSchema
    }
    result = LangChain.Chain.call(schema_chain.chain, inputVariables)

    # Parse the result using the outputParser
    schema_chain.outputParser.(result)
  end

  def noParse(result) do
    result
  end
end
