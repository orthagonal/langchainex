defmodule LangChain.ElixirPrompts.DataStructures do
  def declare_map(map_name, map_structure) do
    "
    <%= map_name %> = <%= map_structure |> Jason.encode!() %>"
  end
end
