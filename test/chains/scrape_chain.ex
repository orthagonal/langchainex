defmodule ScrapeChainTest do
  @moduledoc """
  Tests for ScrapeChain
  """
  use ExUnit.Case

  alias LangChain.{Chain, ChainLink, PromptTemplate}
  alias ScrapeChain

  # Create a parser function for the ChainLink
  defp schema_parser(chain_link, response_text) do
    case Jason.decode(response_text) do
      {:ok, json} ->
        %{
          chain_link
          | raw_responses: response_text,
            output: json
        }

      {:error, response} ->
        %{
          chain_link
          | raw_responses: response_text,
            output: response
        }
    end
  end

  test "scrape function should process input_text and input_schema and return parsed result" do
    # Create PromptTemplate structs for each prompt message
    prompt = %PromptTemplate{
      template:
        "Using the schema <%= input_schema %>, extract relevant information from the text: <%= input_text %>.  Put the extracted data in JSON format so that a computer can parse it"
    }

    # Create a ChainLink with the chat and parser function
    chain_link = %ChainLink{
      name: "schema_extractor",
      input: prompt,
      output_parser: &schema_parser/2
    }

    # Create a Chain with the ChainLink
    chain = %Chain{links: [chain_link]}
    input_schema = "{ name: String, age: Number }"
    schema_chain = LangChain.ScrapeChain.new(chain, input_schema)

    input_text = "John Doe is 30 years old."

    # # Set up the OpenAI LLM provider
    openai_provider = %LangChain.Providers.OpenAI.LanguageModel{
      model_name: "gpt-3.5-turbo",
      max_tokens: 25,
      temperature: 0.5,
      n: 1
    }

    # # Start the LLM GenServer with the OpenAI provider
    {:ok, llm_pid} = LangChain.LLM.start_link(provider: openai_provider)

    result = LangChain.ScrapeChain.scrape(schema_chain, llm_pid, input_text)
    assert Map.get(result, "age") == 30
    assert Map.get(result, "name") == "John Doe"

    # # try some different schemas on the same text
    input_schema2 = "{ name: { first: String, last: String }, age: Number }"
    schema_chain2 = LangChain.ScrapeChain.new(chain, input_schema2)
    result2 = LangChain.ScrapeChain.scrape(schema_chain2, llm_pid, input_text)

    assert Map.get(result2, "name") == %{"first" => "John", "last" => "Doe"}
    assert Map.get(result2, "age") == 30
  end
end
