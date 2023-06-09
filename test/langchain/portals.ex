# credo:disable-for-this-file
defmodule PortalsTest do
  @moduledoc """
  """
  use ExUnit.Case
  alias LangChain.Portals

  describe "simple whirlpool portal" do
    @tag timeout: :infinity
    test "whirlpool_portal" do
      model = %LangChain.Providers.OpenAI.LanguageModel{}

      elixir_code = """
      Jason.decode!("{\"a\": 1")
      """

      {value, bindings} = LangChain.Portals.whirlpool_portal(model, elixir_code, max_steps: 7)
      IO.puts("final result was:")
      IO.inspect(value)
    end

    test "whirlpool_portal more complex example" do
      model = %LangChain.Providers.OpenAI.LanguageModel{}

      elixir_code = """
      # this example is much more complicated than the previous one, and doesn't work correctly
      elixir_map = "
        {\"record\":
          {
            data:
              ref: 1,
              title: "uzumaki"
              author: "Junji Ito"
            }
          }
          "file": "~/uzumaki.json",
          format: "json"
        }"
      """

      {value, bindings} = LangChain.Portals.whirlpool_portal(model, elixir_code, max_steps: 7)
      IO.puts("final result was:")
      IO.inspect(value)
    end
  end
end
