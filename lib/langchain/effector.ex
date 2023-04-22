defmodule LangChain.Effector do
  @moduledoc """
  An Effector is used by a daemon to impact the outside world.
  By default, an Effector should ask for confirmation before
  actually impacting anything.  Daemons are AIs and should not
  be trusted to do the right thing without supervision.
  """
  defstruct [
    mayI?: &LangChain.Effector.defaultMayI?/2,
    no!: &LangChain.Effector.default_no!/2,
    yes!: &LangChain.Effector.default_yes!/2
  ]

  @doc """
  Default function to request permission for an action.
  Returns `true` to allow the action by default.
  Override this function with custom permission handling logic.
  """
  def defaultMayI?(_action, _context) do
    IO.puts "Default permission request function called. Override this function with your custom logic."
    true
  end

  @doc """
  Default function to execute the action.
  Override this function with custom action handling logic.
  """
  def default_yes!(_action, _context) do
    IO.puts "Default invocation function called. Override this function with your custom logic."
  end

  def default_no!(_action, _context) do
    IO.puts "Default nonvocation function called. Override this function with your custom logic."
  end

end
