defmodule LangChain.Scraper do
  use GenServer

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  def list(pid) do
    GenServer.call(pid, :list)
  end

  def add_scrape_chain(pid, name, scrape_chain) do
    GenServer.call(pid, {:add_scrape_chain, name, scrape_chain})
  end

  def scrape(pid, name, input_text, opts \\ []) do
    GenServer.call(pid, {:scrape, name, input_text, opts})
  end

  # Server Callbacks

  def init(_) do
    {:ok, %{}}
  end

  def handle_call(:list, _from, state) do
    result = Enum.map(state, fn {name, scrape_chain} ->
      {name, scrape_chain.chain.inputVariables}
    end)

    {:reply, result, state}
  end

  def handle_call({:add_scrape_chain, name, scrape_chain}, _from, state) do
    new_state = Map.put(state, name, scrape_chain)
    {:reply, :ok, new_state}
  end

  def handle_call({:scrape, name, input_text, opts}, _from, state) do
    scrape_chain = Map.get(state, name)

    if is_nil(scrape_chain) do
      {:reply, {:error, "ScrapeChain not found"}, state}
    else
      input_schema = Keyword.get(opts, :input_schema, scrape_chain.inputSchema)
      output_parser = Keyword.get(opts, :output_parser, scrape_chain.outputParser)

      # Override input_schema or output_parser if provided
      new_scrape_chain = LangChain.ScrapeChain.new(scrape_chain.chain, input_schema, output_parser)
      result = LangChain.ScrapeChain.scrape(new_scrape_chain, input_text)
      {:reply, result, state}
    end
  end
end
