defmodule LangChain.Agents.TheAccountantTest do
  @moduledoc """
  Tests for the LangChain.Agents.TheAccountant module
  """
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

  test ".store and .query will store and then fetch back a report by provider and model name" do
    report = %{
      provider: "provider",
      model_name: "model_name",
      usage: 100,
      rate: 1.0,
      price: 100.0
    }

    TheAccountant.store(report)
    result = TheAccountant.query("provider", "model_name")
    # credo:disable-for-next-line
    IO.inspect(result)
  end

  test "print_to_screen returns :ok" do
    report = %{
      provider: "provider",
      model_name: "model_name",
      usage: 100,
      rate: 1.0,
      price: 100.0
    }

    assert TheAccountant.print_to_screen(report) == :ok
  end
end
