defmodule LangChain.Daemon do
  use GenServer

  @derive Jason.Encoder
  defstruct [
    name: "Paimon",  # give your daemon a name
    chain: %LangChain.Chain{},  # contains the chain that the demon will process
    data: %{},  # contains the current data
    effector: nil,  # Reference to the Effector
    execute_callback: &LangChain.Daemon.default_execute/1  # Default execute callback function
  ]

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  def call(pid, input) do
    GenServer.call(pid, {:call, input})
  end

  # Server Callbacks

  def init(opts) do
    state = %{
      name: Keyword.get(opts, :name, "Paimon"),
      chain: Keyword.get(opts, :chain, %LangChain.Chain{}),
      data: Keyword.get(opts, :data, %{}),
      effector: Keyword.get(opts, :effector, nil),
      execute_callback: Keyword.get(opts, :execute_callback, &default_execute/1)
    }
    {:ok, state}
  end

  def handle_call({:call, input}, _from, state) do
    # Process the chain
    new_data = LangChain.Chain.call(state.chain, Map.merge(state.data, input))

    # Call the execute callback with the final output
    result = state.execute_callback.(new_data)

    # Perform action using the Effector
    effector_result =
      if state.effector do
        LangChain.Effector.perform_action(state.effector, result, new_data)
      else
        {:ok, "No Effector defined"}
      end

    # Update the data in the daemon and return the updated daemon
    new_state = %{state | data: new_data, execute_callback: result}
    {:reply, effector_result, new_state}
  end

  # Default execute callback function, does nothing
  defp default_execute(output) do
    IO.puts "Default execute callback called. Override this function with your custom logic."
    output
  end
end
