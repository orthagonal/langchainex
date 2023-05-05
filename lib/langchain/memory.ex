defmodule LangChain.BaseMemory do
  @moduledoc """
  A GenServer that stores and retrieves memory variables, Memory supports the agent genservers
  """
  use GenServer

  defmacro __using__(_) do
    quote do
      use GenServer

      alias BaseMemory, as: MemoryServer

      # Callbacks
      @impl true
      def init(args) do
        MemoryServer.init(args)
      end

      @impl true
      def handle_call(request, from, state) do
        MemoryServer.handle_call(request, from, state)
      end

      @impl true
      def handle_cast(request, state) do
        MemoryServer.handle_cast(request, state)
      end

      @impl true
      def handle_info(info, state) do
        MemoryServer.handle_info(info, state)
      end

      @impl true
      def terminate(reason, state) do
        MemoryServer.terminate(reason, state)
      end

      @impl true
      def code_change(old_vsn, state, extra) do
        MemoryServer.code_change(old_vsn, state, extra)
      end
    end
  end

  # Server

  def init(_args) do
    state = %{
      input_values: %{},
      output_values: %{},
      memory_variables: %{}
    }

    {:ok, state}
  end

  def handle_call({:load_memory_variables, values}, _from, state) do
    {:reply, state.memory_variables, %{state | input_values: values}}
  end

  def handle_call({:save_context, input_values, output_values}, _from, state) do
    {:reply, :ok, %{state | input_values: input_values, output_values: output_values}}
  end

  def handle_cast(_, state) do
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  def terminate(_reason, _state) do
    :ok
  end

  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end
end

defmodule Utils do
  @moduledoc """
  Utility functions for memory
  """
  def get_input_value(input_values, input_key \\ nil) do
    case input_key do
      nil ->
        keys = Map.keys(input_values)

        if length(keys) == 1 do
          key = hd(keys)
          Map.get(input_values, key)
        else
          raise ArgumentError,
            message:
              "Input values have multiple keys, memory only supported when one key currently: #{inspect(keys)}"
        end

      key ->
        Map.get(input_values, key)
    end
  end

  # def get_buffer_string(messages, human_prefix \\ "Human", ai_prefix \\ "AI") do
  #   messages
  #   |> Enum.map(fn m ->
  #     # all the messages have a 'text' field:
  #     role = case m.get_type() do
  #       :human -> human_prefix
  #       :ai -> ai_prefix
  #       :system -> "System"
  #       # generics will have a 'role' field:
  #       :generic -> m.get_role()
  #       _ -> raise ArgumentError, message: "Got unsupported message type: #{inspect(m)}"
  #     end

  #     "#{role}: #{m.text}"
  #   end)
  #   |> Enum.join("\n")
  # end
end
