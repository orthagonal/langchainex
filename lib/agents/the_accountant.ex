defmodule LangChain.Agents.TheAccountant do
  @moduledoc """
  TheAccountant is responsible for storing and retrieving usage
  and pricing reports
  """
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end

  def query(provider, model_name) do
    handle_process(:query, [provider, model_name])
  end

  def store(report) do
    handle_process(:store, report)
  end

  def post_webhook(url, report) do
    handle_process(:post_webhook, [url, report])
  end

  def print_to_screen(report) do
    handle_process(:print_to_screen, [report])
  end

  defp handle_process(message, args \\ []) do
    case Process.whereis(__MODULE__) do
      nil ->
        # the accountant process is not running so just
        # print the results
        # IO.inspect(message)
        # IO.inspect(args)
        true

      pid when is_pid(pid) ->
        GenServer.call(pid, {message, args})
    end
  end

  def handle_call({:store, report}, _from, state) do
    provider = report[:provider]
    model_name = report[:model_name]

    updated_state =
      state
      |> Map.update(provider, %{model_name => [report]}, fn existing ->
        Map.update(existing, model_name, [report], &[report | &1])
      end)

    IO.inspect(updated_state)
    {:reply, :ok, updated_state}
  end

  def handle_call({query, [provider, model_name]}, _from, state) do
    case Map.fetch(state, provider) do
      {:ok, provider_reports} ->
        case Map.fetch(provider_reports, model_name) do
          {:ok, model_reports} ->
            {:reply, model_reports, state}

          :error ->
            {:reply, [], state}
        end

      :error ->
        {:reply, [], state}
    end
  end

  def handle_call({:post_webhook, [url, report]}, _from, state) do
    # perform the webhook post, e.g. with HTTPoison
    # use the report data as the JSON payload
    {:reply, :ok, state}
  end

  def handle_call({:print_to_screen, [report]}, _from, state) do
    # IO.inspect(report)
    {:reply, :ok, state}
  end
end
