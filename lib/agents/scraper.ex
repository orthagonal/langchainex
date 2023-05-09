defmodule LangChain.Scraper do
  @moduledoc """
  A Scraper is a GenServer that scrapes natural language text and tries to turn it into some kind of
  structured data. It comes with a built in "default_scraper" that can generally extract data
  from text according to the schema you gave it.  Examples:

   {:ok, scraper_pid} = Scraper.start_link()
   input_text = "John Doe is 30 years old."
   {:ok, result} = Scraper.scrape(scraper_pid, input_text)

  {:ok, result_xml} = Scraper.scrape(scraper_pid, input_text, "default_scraper", %{
    output_format: "XML"
  })

  {:ok, result_yml} = Scraper.scrape(scraper_pid, input_text, "default_scraper", %{
    input_schema: "{ name: { first: String, last: String }, age: Number }",
    output_format: "YAML"
  })
  """
  use GenServer

  @timeout 120_000

  alias LangChain.{Chain, ChainLink, PromptTemplate, ScrapeChain}
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
  def scrape(pid, input_text, llm_pid, name \\ "default_scraper", opts \\ %{}) do
    GenServer.call(pid, {:scrape, name, llm_pid, input_text, opts}, @timeout)
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

  # ({:scrape, name, llm_pid, input_text, opts}, @timeout)
  # pid, input_text, llm_pid, name \\ "default_scraper", opts \\ %{
  def handle_call({:scrape, name, llm_pid, input_text, opts}, _from, state) do
    scrape_chain = Map.get(state, name)

    if is_nil(scrape_chain) do
      {:reply, {:error, "ScrapeChain not found"}, state}
    else
      # Override input_schema or output_parser or output_format if provided
      input_schema = Map.get(opts, :input_schema, scrape_chain.input_schema)
      output_parser = Map.get(opts, :output_parser, scrape_chain.output_parser)
      output_format = Map.get(opts, :output_format, "JSON")

      temp_scrape_chain =
        LangChain.ScrapeChain.new(scrape_chain.chain, input_schema, output_parser)

      # override the output_format if provided
      input_variables = %{
        input_text: input_text,
        input_schema: input_schema,
        output_format: output_format
      }

      result = LangChain.ScrapeChain.scrape(temp_scrape_chain, llm_pid, input_variables)
      {:reply, {:ok, result}, state}
    end
  end

  defp default_scrape_chain do
    # can be overruled with the input_schema option
    input_schema = "{ name: String, age: Number }"

    prompt = %PromptTemplate{
      template: """
      Schema: \"\"\"<%= input_schema %>\"\"\"
      Text: \"\"\"<%= input_text %>\"\"\
      Extract the data from Text according to Schema and return it in <%= output_format %> format.
      Format any datetime fields using ISO8601 standard.
      """
    }

    chain_link = %ChainLink{
      name: "schema_extractor",
      input: prompt,
      output_parser: &passthru_parser/2
    }

    chain = %Chain{links: [chain_link]}
    output_parser = &output_parser/1
    ScrapeChain.new(chain, input_schema, output_parser)
  end

  @doc """
  A default output parser that just returns the first response text
  """
  def passthru_parser(chain_link, response_text) do
    %{
      chain_link
      | raw_responses: response_text,
        output: %{
          text: response_text
        }
    }
  end

  @doc """
  A default output parser that just returns the first response text as json
  """
  def json_parser(chain_link, outputs) do
    case Jason.decode(outputs) do
      {:ok, json} ->
        %{
          chain_link
          | raw_responses: outputs,
            output: json
        }

      {:error, _response} ->
        # json may not have been formatted correctly, try custom_parser

        %{
          chain_link
          | raw_responses: outputs,
            output: outputs
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
