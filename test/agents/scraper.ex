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
          rawResponses: outputs,
          output: json
        }
      {:error, response} ->
        IO.inspect response
        IO.inspect response_text
        %{
          chain_link |
          rawResponses: outputs,
          output: response_text
        }
    end
  end

  test "scrape/4 processes a given piece of natural-language text", %{pid: pid} do
    # Define a sample ScrapeChain
    input_schema = "{ name: String, age: Number }"

    chat = Chat.addPromptTemplates(%Chat{}, [
      %{
        role: "user",
        prompt: %PromptTemplate{
          template: "Using the schema <%= inputSchema %>, extract relevant information from the text: <%= inputText %>"
        }
      },
      %{
        role: "user",
        prompt: %PromptTemplate{
          template: "Put the extracted data in JSON format so that a computer can parse it."
        }
      }
    ])

    chain_link = %ChainLink{
      name: "schema_extractor",
      input: chat,
      outputParser: &schema_parser/2
    }

    chain = %Chain{links: [chain_link]}
    output_parser = &output_parser/1
    scrape_chain = ScrapeChain.new(chain, input_schema, output_parser)

    # Add the ScrapeChain to the Scraper
    Scraper.add_scrape_chain(pid, :sample_chain, scrape_chain)

    # Test the :scrape call
    input_text = "John Doe is 30 years old."
    result1 = Scraper.scrape(pid, :sample_chain, input_text)

    # Define another ScrapeChain with a different schema
    input_schema2 = "{ name: { first: String, last: String }, age: Number }"
    scrape_chain2 = ScrapeChain.new(chain, input_schema2, output_parser)

    # # Add the second ScrapeChain to the Scraper
    Scraper.add_scrape_chain(pid, :sample_chain2, scrape_chain2)

    # Test the :scrape call with the second ScrapeChain
    result2 = Scraper.scrape(pid, :sample_chain2, input_text)

    # verify that result1 and result2 both have the "age" field of 30 and the "name" field of "John Doe" or name.first of "John" and name.last of "Doe"
    assert Map.get(result1, "age") == 30
    assert Map.get(result1, "name") == "John Doe"
    assert Map.get(result2, "name") == %{"first" => "John", "last" => "Doe"}
    assert Map.get(result2, "age") == 30
  end

end
