defmodule LangChain.ScraperTest do
  @moduledoc """
  Tests for LangChain.Scraper
  """
  use ExUnit.Case, async: true
  alias LangChain.{Chain, ChainLink, PromptTemplate, Scraper}
  require Logger

  @tag timeout: :infinity
  setup do
    {:ok, pid} = Scraper.start_link()
    # Set up the Bumblebee LLM provider
    # any usable model that i've seen on huggingface so far has been in the 7b range (10's of gb in size)
    # bumblebee will download the entire model from the internet to run it on your local machine
    # Make sure you know what model you're downloading and have a processor that can tank it
    # I put Nous Hermes here by way of example but you might want to test your model out
    # on Huggingface before committing to downloading it to your own machine
    bumblebee_provider = %LangChain.Providers.Bumblebee.LanguageModel{
      model_name: "NousResearch/Nous-Hermes-Llama2-13b",
      max_new_tokens: 25,
      temperature: 0.5
    }

    # # Start the LLM GenServer with the Bumblebee provider
    {:ok, llm_pid} = LangChain.LLM.start_link(provider: bumblebee_provider)
    {:ok, %{pid: pid, llm_pid: llm_pid}}
  end

  defp output_parser(result) do
    result
  end

  # NOTE: you must use a model that actually outputs JSON for this to work
  defp schema_parser(chain_link, outputs) do
    case Jason.decode(outputs) do
      {:ok, json} ->
        %{
          chain_link
          | raw_responses: outputs,
            output: json
        }

      _ ->
        %{
          chain_link
          | raw_responses: outputs,
            output: %{}
        }
    end
  end

  @tag timeout: :infinity
  test "scrape/4 processes a given piece of natural-language text", %{pid: pid, llm_pid: llm_pid} do
    # Define a sample ScrapeChain
    input_schema = "{ name: String, age: Number }"

    chain_link = %ChainLink{
      name: "schema_extractor",
      input: %PromptTemplate{
        template:
          "Using the schema <%= input_schema %>, extract relevant information from the text: <%= input_text %>.
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
    res = Scraper.scrape(pid, input_text, llm_pid, :sample_chain)
    IO.puts "res: #{inspect res}"
    # # Define another ScrapeC hain with a different schema
    input_schema2 = "{ name: { first: String, last: String }, age: Number }"
    scrape_chain2 = LangChain.ScrapeChain.new(chain, input_schema2, output_parser)

    # # # Add the second ScrapeChain to the Scraper
    Scraper.add_scrape_chain(pid, :sample_chain2, scrape_chain2)

    # # Test the :scrape call with the second ScrapeChain
    {:ok, result2} = Scraper.scrape(pid, input_text, llm_pid, :sample_chain2)

    # # verify that result1 and result2 both have the "age" field of 30 and the "name" field of "John Doe" or name.first of "John" and name.last of "Doe"
    assert Map.get(result1, "age") == 30
    assert Map.get(result1, "name") == "John Doe"
    assert Map.get(result2, "name") == %{"first" => "John", "last" => "Doe"}
    assert Map.get(result2, "age") == 30
  end
end
