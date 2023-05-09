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

  defp default_provider() do
    IO.warn(
      "No :provider option specified, will fallback to default provider from the application environment defined in :language_model_provider."
    )

    Application.get_env(:lang_chain, :language_model_provider)
  end

  # GenServer callbacks

  def init(state) do
    {:ok, state}
  end

  def handle_call({:call, prompt}, _from, state) do
    result = LanguageModelProtocol.call(state.provider, prompt)
    {:reply, result, state}
  end

  def handle_call({:chat, chats}, _from, state) do
    result = LanguageModelProtocol.chat(state.provider, chats)
    {:reply, result, state}
  end

  # Public functions

  def call(pid, prompt) do
    GenServer.call(pid, {:call, prompt}, 60_000)
  end

  def chat(pid, msgs) do
    GenServer.call(pid, {:chat, msgs}, 60_000)
  end
end
