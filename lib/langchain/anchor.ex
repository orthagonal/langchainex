defmodule LangChain.Anchor.Behavior do
  @moduledoc """
    An Anchor is a point at the end of a chain where the AI confirms with (hopefully) a human that the result of the
    chain is 'in alignment' before moving on. AI programming differs from traditional programming because it's inherently
    hard to predict what it will actually do at run-time. This means that best practice is to anchor your chains so that
    at runtime a human (or at least a traditional hard-coded computer program) can confirm the AI isn't doing something
    harmful or WOPRish.

    Anchors are implemented as a behavior so that you can implement your own anchor, in addition to
    the CLI and Web anchors in this library. By design they should be predictable and rigorous in terms
    of output.  Don't get creative and try to add natural-language processing to an anchor, because the
    whole point of an anchor is to eliminate ambiguity about what's going on.
  """
  @callback present_information(action_type :: atom(), info :: String.t()) :: any()
  @callback get_confirmation() :: :yes | :no
end

defmodule LangChain.Anchor.CLI do
  @moduledoc """
    An anchor for getting confirmation at run-time from the command line
  """
  @behaviour LangChain.Anchor.Behavior

  @doc """
    Queries don't have side-effects. This presents the information to the user and asks for
    confirmation if it looks correct
  """
  def present_information(:query, info) do
    IO.puts("Query:")
    IO.puts(info)
    IO.puts("Does this look like the right information? (y/n)")
  end

  # @doc """
  #   Effectors have side-effects. This present the information to the user and warn of any potential dangers
  #   and then ask for confirmation if they want to proceed.
  # """
  def present_information(:effector, info) do
    IO.puts("Effector:")
    IO.puts(info)
    IO.puts("Warning: There might be potential dangers associated with this action.")
    IO.puts("Do you want to proceed? (y/n)")
  end

  @doc """
  returns either :yes or :no depending on the user's input
  """
  def get_confirmation do
    case IO.gets(">> ") do
      "y\n" -> :yes
      "n\n" -> :no
      _ -> get_confirmation()
    end
  end
end

# defmodule LangChain.Anchor.Phoenix do
#   @moduledoc """
#     An anchor for getting confirmation at run-time from a Phoenix web app
#   """
#   @behaviour LangChain.Anchor.Behavior
#   alias Plug.Conn

#   def present_information(conn, template, action_type, info) do
#     assigns = %{
#       action_type: action_type,
#       info: info
#     }

#     # This assumes you have a render/3 function in your controller that takes conn, template, and assigns
#     conn
#     |> render(template, assigns)
#   end

#   def get_confirmation() do
#     raise "get_confirmation/0 is not supported in the Phoenix implementation." <>
#       " Use a form submission to get user confirmation."
#   end
# end
