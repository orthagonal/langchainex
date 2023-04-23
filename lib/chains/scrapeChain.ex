defmodule LangChain.ScrapeChain do
  @moduledoc """
  Use this when you want to extract formatted data from natural-language text, ScrapeChain is basically
  a special form of QueryChain.
  ScrapeChain is a wrapper around a special type of Chain that requires 'inputSchema' and 'inputText' in its
  inputVariables and combines it with an outputParser.
  Once you define that chain, you can 'scrape' the ScrapeChain to run the chain and return the
  formatted output in any form.
  """

  @derive Jason.Encoder
  defstruct [
    chain: %LangChain.Chain{},
    inputSchema: "",
    outputParser: &LangChain.ScrapeChain.noParse/1
  ]

  def new(chain, inputSchema, outputParser \\ &LangChain.ScrapeChain.noParse/1) do
    %LangChain.ScrapeChain{
      chain: chain,
      inputSchema: inputSchema,
      outputParser: outputParser
    }
  end

  def scrape(scrape_chain, input_text) do
    IO.inspect "Scraping"
    IO.inspect "Scraping"
    IO.inspect "Scraping"
    # Fill in the inputText and inputSchema values and run the Chain
    inputVariables = %{
      inputText: input_text,
      inputSchema: scrape_chain.inputSchema
    }
    IO.inspect inputVariables
    IO.inspect scrape_chain.chain
    IO.inspect input_text
    result = LangChain.Chain.call(scrape_chain.chain, inputVariables)
    IO.inspect result
    # Parse the result using the outputParser
    scrape_chain.outputParser.(result)
  end

  def noParse(result) do
    result
  end
end
