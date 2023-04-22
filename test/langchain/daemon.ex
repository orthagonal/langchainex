defmodule LangChain.DaemonTest do
  use ExUnit.Case
  alias LangChain.Daemon
  alias LangChain.Chain
  alias LangChain.ChainLink
  alias LangChain.Effector

  # Dummy ChainLink that multiplies the input by 2
  defp dummy_chain_link() do
    %ChainLink{
      name: "Multiply by 2",
      input: %LangChain.Chat{},
      outputParser: &dummy_parser/2
    }
  end

  defp dummy_parser(chain_link, _response) do
    output = %{number: chain_link.data.number * 2}
    %{chain_link | output: output}
  end

  defp test_effector() do
    %Effector{
      mayI?: &always_granted/2,
      yes!: &print_result/2,
      no!: &print_denied/2
    }
  end

  defp always_granted(_action, _context) do
    true
  end

  defp print_result(result, _context) do
    IO.puts "Action executed: #{inspect(result)}"
  end

  defp print_denied(_action, _context) do
    IO.puts "Action denied"
  end

  test "daemon processes the chain and uses effector" do
    # Start the daemon with a chain containing the dummy ChainLink and test Effector
    {:ok, daemon_pid} = Daemon.start_link(chain: %Chain{links: [dummy_chain_link()]}, effector: test_effector())

    input = %{number: 5}

    # Call the daemon and process the chain
    result = Daemon.call(daemon_pid, input)

    # Assert the result is as expected
    assert result == :ok
  end
end
