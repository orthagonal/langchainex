defmodule LangChain.ScraperTest do
  @moduledoc """
  Tests for LangChain.Scraper
  """
  use ExUnit.Case, async: true
  alias LangChain.{Chain, ChainLink, PromptTemplate, Scraper}
  require Logger

  setup do
    {:ok, pid} = Scraper.start_link()
    # Set up the OpenAI LLM provider
    openai_provider = %LangChain.Providers.OpenAI{
      model_name: "gpt-3.5-turbo",
      max_tokens: 25,
      temperature: 0.5,
      n: 1
    }

    # # Start the LLM GenServer with the OpenAI provider
    {:ok, llm_pid} = LangChain.LLM.start_link(provider: openai_provider)
    {:ok, %{pid: pid, llm_pid: llm_pid}}
  end

  defp output_parser(result) do
    result
  end

  defp schema_parser(chain_link, outputs) do
    case Jason.decode(outputs) do
      {:ok, json} ->
        %{
          chain_link
          | raw_responses: outputs,
            output: json
        }

      {:error, _response} ->
        %{
          chain_link
          | raw_responses: outputs,
            output: outputs
        }
    end
  end

  test "scrape/4 processes a given piece of natural-language text", %{pid: pid, llm_pid: llm_pid } do
    # Define a sample ScrapeChain
    input_schema = "{ name: String, age: Number }"

    chain_link = %ChainLink{
      name: "schema_extractor",
      input:  %PromptTemplate{
        template: "Using the schema <%= input_schema %>, extract relevant information from the text: <%= input_text %>.
        Use double quotes for all keys and present it so that it can be parsed by a standard parser."
      },
      output_parser: &schema_parser/2
    }

    chain = %Chain{links: [chain_link]}
    output_parser = &output_parser/1
    scrape_chain = LangChain.ScrapeChain.new(chain, input_schema, output_parser)

    # Add the ScrapeChain to the Scraper
    Scraper.add_scrape_chain(pid, :sample_chain, scrape_chain)

    # Test the :scrape call
    input_text = "John Doe is 30 years old."
    {:ok, result1} = Scraper.scrape(pid, input_text, llm_pid, :sample_chain)

    # # Define another ScrapeChain with a different schema
    input_schema2 = "{ name: { first: String, last: String }, age: Number }"
    scrape_chain2 = LangChain.ScrapeChain.new(chain, input_schema2, output_parser)

    # # # Add the second ScrapeChain to the Scraper
    Scraper.add_scrape_chain(pid, :sample_chain2, scrape_chain2)

    # # Test the :scrape call with the second ScrapeChain
    {:ok, result2} = Scraper.scrape(pid, input_text, llm_pid, :sample_chain2)

    # # # verify that result1 and result2 both have the "age" field of 30 and the "name" field of "John Doe" or name.first of "John" and name.last of "Doe"
    assert Map.get(result1, "age") == 30
    assert Map.get(result1, "name") == "John Doe"
    assert Map.get(result2, "name") == %{"first" => "John", "last" => "Doe"}
    assert Map.get(result2, "age") == 30
  end

  test "successfully extracts information using the default scraper", %{pid: _pid, llm_pid: llm_pid } do
    {:ok, scraper_pid} = Scraper.start_link()
    input_text = "John Doe is 30 years old."
    {:ok, result} = Scraper.scrape(scraper_pid, input_text, llm_pid)

    Logger.log(:debug, result.text)

    # Test with a custom output format (e.g., XML)
    # add support for calling if it is a map
    # actually don't worry too much about this for now move on to impl on the page
    # Note: You need to update the schema_parser/2 function to handle XML format if you want to use it.
    {:ok, result_xml} =
      Scraper.scrape(scraper_pid, input_text, llm_pid, "default_scraper", %{
        output_format: "XML"
      })

    Logger.log(:debug, result_xml.text)

    {:ok, result_yml} =
      Scraper.scrape(scraper_pid, input_text, llm_pid, "default_scraper", %{
        input_schema: "{ name: { first: String, last: String }, age: Number }",
        output_format: "YAML"
      })

    Logger.log(:debug, result_yml.text)
  end
end
