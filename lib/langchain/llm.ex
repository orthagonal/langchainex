defmodule LangChain.LLM do
  @moduledoc """
  Language Model GenServer
  """
  use GenServer
  alias LangChain.LanguageModelProtocol

  def start_link(opts \\ []) do
    provider = Keyword.get(opts, :provider) || default_provider()
    GenServer.start_link(__MODULE__, %{provider: provider})
  end

  defp default_provider do
    IO.warn(
      "No :provider option specified, will fallback to default provider from the application environment defined in :language_model_provider."
    )

    Application.get_env(:lang_chain, :language_model_provider)
  end

  # GenServer callbacks

  def init(state) do
    {:ok, state}
  end

  def handle_call({:ask, prompt}, _from, state) do
    result = LanguageModelProtocol.ask(state.provider, prompt)
    {:reply, {:ok, result}, state}
  end

  # Public functions

  def call(pid, prompt) do
    GenServer.call(pid, {:ask, prompt}, 60_000)
  end
end
