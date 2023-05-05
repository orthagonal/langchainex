defmodule LangChain.ScrapeChain do
  @moduledoc """
  Use this when you want to extract formatted data from natural-language text, ScrapeChain is basically
  a special form of QueryChain.
  ScrapeChain is a wrapper around a special type of Chain that requires 'inputSchema' and 'inputText' in its
  inputVariables and combines it with an outputParser.
  Once you define that chain, you can have the chain 'scrape' a text and return the
  formatted output in virtually any form.
  """

  @derive Jason.Encoder
  defstruct chain: %LangChain.Chain{},
            inputSchema: "",
            outputParser: &LangChain.ScrapeChain.noParse/1

  @doc """
  Creates a new ScrapeChain struct with the given chain, inputSchema, and outputParser,
  you set up a scrapeChain with an inputSchema and an outputParser, then you can call
  it with whatever text you want.

  ## Example:

  # create a chat to extract data:
  chat = Chat.addPromptTemplates(%Chat{}, [
    %{
      role: "user",
      prompt: %PromptTemplate{
        template: "Schema: \"\"\"
        <%= inputSchema %>
      \"\"\"
      Text: \"\"\"
        <%= inputText %>
      \"\"\
      Extract the data from Text according to Schema and return it in <%= outputFormat %> format.
      Format any datetime fields using ISO8601 standard.
      "
      }
    }
  ])

  # create a ChainLink with the chat and parser function
  chain_link = %ChainLink{
    name: "schema_extractor",
    input: chat,
    outputParser: &schema_parser/2
  }

  chain = %Chain{links: [chain_link]}
  input_schema = "{ name: String, age: Number, birthdate: Date }"
  schema_chain = LangChain.ScrapeChain.new(chain, input_schema)
  """
  def new(chain, inputSchema, outputParser \\ &LangChain.ScrapeChain.noParse/1) do
    %LangChain.ScrapeChain{
      chain: chain,
      inputSchema: inputSchema,
      outputParser: outputParser
    }
  end

  @doc """
  Executes the scrapechain on a simple string input and returns the parsed result:

    result = LangChain.ScrapeChain.scrape(schema_chain, "John Doe is 30 years old")
  """
  def scrape(scrape_chain, inputVariables) when is_map(inputVariables) do
    result = LangChain.Chain.call(scrape_chain.chain, inputVariables)
    # Parse the result using the outputParser
    scrape_chain.outputParser.(result)
  end

  @doc """
  Executes the ScrapeChain with a specific inputText and inputSchema and returns the parsed result:
    inputVariables = %{
      inputText: "John Doe is 30 years old.",
      inputSchema: "{ name: String, age: Number, birthdate: Date }"
    }
  """
  def scrape(scrape_chain, input_text) when is_binary(input_text) do
    # Fill in the inputText and inputSchema values and run the Chain
    inputVariables = %{
      inputText: input_text,
      inputSchema: scrape_chain.inputSchema
    }

    result = LangChain.Chain.call(scrape_chain.chain, inputVariables)
    # Parse the result using the outputParser
    scrape_chain.outputParser.(result)
  end

  @doc """
  default passthrough parser.  'result' will be a string so it is
  up to you to transform it into a native elixir structure or whatever you want.
  """
  def noParse(result) do
    result
  end
end
