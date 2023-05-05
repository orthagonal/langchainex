defmodule ScrapeChainTest do
  use ExUnit.Case

  alias LangChain.{Chat, ChainLink, Chain, PromptTemplate}
  alias ScrapeChain

  # Create a parser function for the ChainLink
  defp schema_parser(chain_link, outputs) do
    response_text = outputs |> List.first() |> Map.get(:text)

    case Jason.decode(response_text) do
      {:ok, json} ->
        %{
          chain_link
          | raw_responses: outputs,
            output: json
        }

      {:error, response} ->
        IO.inspect(response)
        IO.inspect(response_text)

        %{
          chain_link
          | raw_responses: outputs,
            output: response_text
        }
    end
  end

  test "scrape function should process input_text and input_schema and return parsed result" do
    # Create PromptTemplate structs for each prompt message
    chat =
      Chat.add_prompt_templates(%Chat{}, [
        %{
          role: "user",
          prompt: %PromptTemplate{
            template:
              "Using the schema <%= input_schema %>, extract relevant information from the text: <%= input_text %>"
          }
        },
        %{
          role: "user",
          prompt: %PromptTemplate{
            template: "Put the extracted data in JSON format so that a computer can parse it. "
          }
        }
      ])

    # Create a ChainLink with the chat and parser function
    chain_link = %ChainLink{
      name: "schema_extractor",
      input: chat,
      output_parser: &schema_parser/2
    }

    # Create a Chain with the ChainLink
    chain = %Chain{links: [chain_link]}
    input_schema = "{ name: String, age: Number }"
    schema_chain = LangChain.ScrapeChain.new(chain, input_schema)

    input_text = "John Doe is 30 years old."

    result = LangChain.ScrapeChain.scrape(schema_chain, input_text)
    IO.puts("****************")
    IO.inspect(result)
    assert Map.get(result, "age") == 30
    assert Map.get(result, "name") == "John Doe"

    # try some different schemas on the same text
    input_schema2 = "{ name: { first: String, last: String }, age: Number }"
    schema_chain2 = LangChain.ScrapeChain.new(chain, input_schema2)
    result2 = LangChain.ScrapeChain.scrape(schema_chain2, input_text)
    IO.inspect(result2)
    assert Map.get(result2, "name") == %{"first" => "John", "last" => "Doe"}
    assert Map.get(result2, "age") == 30
  end
end
