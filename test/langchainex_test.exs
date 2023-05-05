defmodule LangchainExTest do
  use ExUnit.Case
  doctest LangchainEx

  test "greets the world" do
    assert LangchainEx.hello() == :world
  end
end
