defmodule LangChain.ScraperTest do
  use ExUnit.Case, async: true
  alias LangChain.{ScrapeChain, Scraper, ChainLink, Chat, PromptTemplate, Chain}

  setup do
    {:ok, pid} = Scraper.start_link()
    {:ok, %{pid: pid}}
  end

  defp output_parser(result) do
    result
  end

  defp schema_parser(chain_link, outputs) do
    response_text = outputs |> List.first() |> Map.get(:text)

    case Jason.decode(response_text) do
      {:ok, json} ->
        %{
          chain_link |
          raw_responses: outputs,
          output: json
        }

      {:error, response} ->
        IO.inspect(response)
        IO.inspect(response_text)

        %{
          chain_link |
          raw_responses: outputs,
          output: response_text
        }
    end
  end

  test "scrape/4 processes a given piece of natural-language text", %{pid: pid} do
    # Define a sample ScrapeChain
    input_schema = "{ name: String, age: Number }"

    chat = Chat.add_prompt_templates(%Chat{}, [
      %{
        role: "user",
        prompt: %PromptTemplate{
          template: "Using the schema <%= input_schema %>, extract relevant information from the text: <%= input_text %>"
        }
      ])

    chain_link = %ChainLink{
      name: "schema_extractor",
      input: chat,
      output_parser: &schema_parser/2
    }

    chain = %Chain{links: [chain_link]}
    output_parser = &output_parser/1
    scrape_chain = ScrapeChain.new(chain, input_schema, output_parser)

    # Add the ScrapeChain to the Scraper
    Scraper.add_scrape_chain(pid, :sample_chain, scrape_chain)

    # IO.inspect Scraper.list(pid)
    # Test the :scrape call
    input_text = "John Doe is 30 years old."
    {:ok, result1} = Scraper.scrape(pid, input_text, :sample_chain)

    # Define another ScrapeChain with a different schema
    input_schema2 = "{ name: { first: String, last: String }, age: Number }"
    scrape_chain2 = ScrapeChain.new(chain, input_schema2, output_parser)

    # # Add the second ScrapeChain to the Scraper
    Scraper.add_scrape_chain(pid, :sample_chain2, scrape_chain2)

    # Test the :scrape call with the second ScrapeChain
    {:ok, result2} = Scraper.scrape(pid, input_text, :sample_chain2)

    IO.inspect(result1)
    IO.inspect(result2)

    # # verify that result1 and result2 both have the "age" field of 30 and the "name" field of "John Doe" or name.first of "John" and name.last of "Doe"
    assert Map.get(result1, "age") == 30
    assert Map.get(result1, "name") == "John Doe"
    assert Map.get(result2, "name") == %{"first" => "John", "last" => "Doe"}
    assert Map.get(result2, "age") == 30
  end

  test "successfully extracts information using the default scraper" do
    {:ok, scraper_pid} = Scraper.start_link()
    input_text = "John Doe is 30 years old."
    {:ok, result} = Scraper.scrape(scraper_pid, input_text)
    IO.inspect(result)
    # Test with a custom output format (e.g., XML)
    # add support for calling if it is a map
    # actually don't worry too much about this for now move on to impl on the page
    # Note: You need to update the schema_parser/2 function to handle XML format if you want to use it.
    {:ok, result_xml} = Scraper.scrape(scraper_pid, input_text, "default_scraper", %{
      output_format: "XML"
    })
    IO.inspect result_xml

    {:ok, result_yml} = Scraper.scrape(scraper_pid, input_text, "default_scraper", %{
      input_schema: "{ name: { first: String, last: String }, age: Number }",
      output_format: "YAML"
    })
    IO.inspect result_yml
  end
end
