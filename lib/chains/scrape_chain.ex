defmodule LangChain.ScrapeChain do
  @moduledoc """
  Use this when you want to extract formatted data from natural-language text, ScrapeChain is basically
  a special form of QueryChain.
  ScrapeChain is a wrapper around a special type of Chain that requires 'input_schema' and 'input_text' in its
  input_variables and combines it with an output_parser.
  Once you define that chain, you can have the chain 'scrape' a text and return the
  formatted output in virtually any form.
  """

  @derive Jason.Encoder
  defstruct chain: %LangChain.Chain{},
            input_schema: "",
            output_parser: &LangChain.ScrapeChain.no_parse/1

  @doc """
  Creates a new ScrapeChain struct with the given chain, input_schema, and output_parser,
  you set up a scrapeChain with an input_schema and an output_parser, then you can call
  it with whatever text you want.

  ## Example:

  # create a chat to extract data:
  chat = Chat.add_prompt_templates(%Chat{}, [
    %{
      role: "user",
      prompt: %PromptTemplate{
        template: "Schema: \"\"\"
        <%= input_schema %>
      \"\"\"
      Text: \"\"\"
        <%= input_text %>
      \"\"\
      Extract the data from Text according to Schema and return it in <%= output_format %> format.
      Format any datetime fields using ISO8601 standard.
      "
      }
    }
  ])

  # create a ChainLink with the chat and parser function
  chain_link = %ChainLink{
    name: "schema_extractor",
    input: chat,
    output_parser: &schema_parser/2
  }

  chain = %Chain{links: [chain_link]}
  input_schema = "{ name: String, age: Number, birthdate: Date }"
  schema_chain = LangChain.ScrapeChain.new(chain, input_schema)
  """
  def new(chain, input_schema, output_parser \\ &LangChain.ScrapeChain.no_parse/1) do
    %LangChain.ScrapeChain{
      chain: chain,
      input_schema: input_schema,
      output_parser: output_parser
    }
  end

  @doc """
  Executes the scrapechain and returns the parsed result, can be called against
  the schema you defined when you made the chain, or you can override that schema:

    result = LangChain.ScrapeChain.scrape(schema_chain, "John Doe is 30 years old")
    # result will be %{ name: "John Doe", age: 30, birthdate: "1987-01-01"}

    # override the default schema
    input_variables = %{
      input_text: "John Doe is 30 years old.",
      input_schema: "{ firstName: String, lastName: String, age: Number, birthdate: Date }"
    }
    alt_result = LangChain.ScrapeChain.scrape(schema_chain, input_variables)
    # alt_result will be %{ firstName: "John", lastName: "Doe", age: 30, birthdate: "1987-01-01"}
  """
  def scrape(scrape_chain, llm_pid, input_variables) when is_map(input_variables) do
    result = LangChain.Chain.call(scrape_chain.chain, llm_pid, input_variables)
    # Parse the result using the output_parser
    scrape_chain.output_parser.(result)
  end

  def scrape(scrape_chain, llm_pid, input_text) when is_binary(input_text) do
    # Fill in the input_text and input_schema values and run the Chain
    input_variables = %{
      input_text: input_text,
      input_schema: scrape_chain.input_schema
    }

    result = LangChain.Chain.call(scrape_chain.chain, llm_pid, input_variables)
    # Parse the result using the output_parser
    scrape_chain.output_parser.(result)
  end


  @doc """
  default passthrough parser.  'result' will be a string so it is
  up to you to transform it into a native elixir structure or whatever you want.
  """
  def no_parse(result) do
    result
  end
end
