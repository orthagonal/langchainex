defmodule LangchainexTest do
  use ExUnit.Case
  doctest Langchainex

  test "greets the world" do
    assert Langchainex.hello() == :world
  end
end
