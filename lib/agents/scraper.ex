defmodule LangChain.Scraper do
  @moduledoc """
  A Scraper is a GenServer that scrapes natural language text and tries to turn it into some kind of
  structured data. It comes with a built in "default_scraper" that can generally extract data
  from text according to the schema you gave it.  Examples:

   {:ok, scraper_pid} = Scraper.start_link()
   input_text = "John Doe is 30 years old."
   {:ok, result} = Scraper.scrape(scraper_pid, input_text)

  {:ok, result_xml} = Scraper.scrape(scraper_pid, input_text, "default_scraper", %{
    outputFormat: "XML"
  })

  {:ok, result_yml} = Scraper.scrape(scraper_pid, input_text, "default_scraper", %{
    inputSchema: "{ name: { first: String, last: String }, age: Number }",
    outputFormat: "YAML"
  })
  """
  use GenServer

  @timeout 120_000

  alias LangChain.{ScrapeChain, ChainLink, Chat, PromptTemplate, Chain}
  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  def init(_) do
    default_scrape_chain = default_scrape_chain()
    state = %{"default_scraper" => default_scrape_chain}
    {:ok, state}
  end

  @doc """
  Returns a list of all the scrape chains in the Scraper
  """
  def list(pid) do
    GenServer.call(pid, :list)
  end

  @doc """
  add your own custom scrape chain to the Scraper
  """
  def add_scrape_chain(pid, name, scrape_chain) do
    GenServer.call(pid, {:add_scrape_chain, name, scrape_chain})
  end

  @doc """
  scrape some text using the default scraper
  """
  def scrape(pid, input_text, name \\ "default_scraper", opts \\ %{}) do
    GenServer.call(pid, {:scrape, name, input_text, opts}, @timeout)
  end

  def handle_call(:list, _from, state) do
    result =
      Enum.map(state, fn {name, scrape_chain} ->
        {name, scrape_chain}
      end)

    {:reply, result, state}
  end

  def handle_call({:add_scrape_chain, name, scrape_chain}, _from, state) do
    new_state = Map.put(state, name, scrape_chain)
    {:reply, :ok, new_state}
  end

  def handle_call({:scrape, name, inputText, opts}, _from, state) do
    scrape_chain = Map.get(state, name)

    if is_nil(scrape_chain) do
      {:reply, {:error, "ScrapeChain not found"}, state}
    else
      # Override inputSchema or outputParser or outputFormat if provided
      inputSchema = Map.get(opts, :inputSchema, scrape_chain.inputSchema)
      outputParser = Map.get(opts, :outputParser, scrape_chain.outputParser)
      outputFormat = Map.get(opts, :outputFormat, "JSON")

      temp_scrape_chain = LangChain.ScrapeChain.new(scrape_chain.chain, inputSchema, outputParser)

      # override the outputFormat if provided
      input_variables = %{
        inputText: inputText,
        inputSchema: inputSchema,
        outputFormat: outputFormat
      }

      result = LangChain.ScrapeChain.scrape(temp_scrape_chain, input_variables)
      {:reply, {:ok, result}, state}
    end
  end

  # # todo: should I move this to the ScrapeChain module?
  defp default_scrape_chain() do
    # can be overruled with the inputSchema option
    input_schema = "{ name: String, age: Number }"

    chat =
      Chat.addPromptTemplates(%Chat{}, [
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

    chain_link = %ChainLink{
      name: "schema_extractor",
      input: chat,
      outputParser: &passthru_parser/2
    }

    chain = %Chain{links: [chain_link]}
    output_parser = &output_parser/1
    scrape_chain = ScrapeChain.new(chain, input_schema, output_parser)
  end

  @doc """
  A default output parser that just returns the first response text
  """
  def passthru_parser(chain_link, outputs) do
    response_text = outputs |> List.first() |> Map.get(:text)

    %{
      chain_link
      | rawResponses: outputs,
        output: %{
          text: response_text
        }
    }
  end

  @doc """
  A default output parser that just returns the first response text as json
  """
  def json_parser(chain_link, outputs) do
    response_text = outputs |> List.first() |> Map.get(:text)

    case Jason.decode(response_text) do
      {:ok, json} ->
        %{
          chain_link
          | rawResponses: outputs,
            output: json
        }

      {:error, response} ->
        %{
          chain_link
          | rawResponses: outputs,
            output: response_text
        }
    end
  end

  @doc """
  simple passthrough parser that just returns the result
  """
  def output_parser(result) do
    result
  end
end
