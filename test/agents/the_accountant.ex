defmodule LangChain.Agents.TheAccountantTest do
  use ExUnit.Case

  alias LangChain.Agents.TheAccountant

  setup do
    # Ensure the GenServer is running
    {:ok, _pid} = TheAccountant.start_link()
    :ok
  end

  # test "query returns an empty list when no reports are stored" do
  #   assert TheAccountant.query("provider", "model_name") == []
  # end

  test "store stores a report" do
    report = %{
      provider: "provider",
      model_name: "model_name",
      usage: 100,
      rate: 1.0,
      price: 100.0
    }

    TheAccountant.store(report)
    result = TheAccountant.query("provider", "model_name")
    IO.inspect(result)
  end

  # test "print_to_screen returns :ok" do
  #   report = %{
  #     provider: "provider",
  #     model_name: "model_name",
  #     usage: 100,
  #     rate: 1.0,
  #     price: 100.0
  #   }

  #   assert TheAccountant.print_to_screen(report) == :ok
  # end
end
