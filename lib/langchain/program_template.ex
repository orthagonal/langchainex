
defmodule LangChain.ProgramTemplate do
  @moduledoc """
  A ProgramTemplate is a template that is filled out and fed to a programming language interpreter,
  compiler or VM. In most cases, this means we are passing Elixir code to the BEAM.
  This is an example of migrating data from the AI knowledge domain to the programming domain.
  """

  @derive Jason.Encoder
  defstruct [
    description: "Hello World",
    # template is a string
    template: "IO.puts \"Hello World\"",
    # input_variables is a list of variables that need to be specified for that template
    input_variables: [],
    # partial_variables is a map of variables that have already been specified and can be applied to the template
    partial_variables: %{},
    language: :elixir
  ]

  # You may want to move this function to a common module if it's used by both LangChain.ProgramTemplate and LangChain.PromptTemplate
  def format(template, values) do
    # env is a keyword list merging values and partials and convert
    env =
      Map.merge(values, template.partial_variables)
      |> Map.to_list()
      |> Enum.map(fn {k, v} ->
        if is_function(v) do
          case v.() do
            {:ok, res} -> {k, res}
            _ -> {k, "[template function #{k} failed to render]"}
          end
        else
          {k, v}
        end
      end)

    outcome = template.template |> EEx.eval_string(env)
    {:ok, outcome}
  end

  def partial(template, partial) do
    keys = Map.keys(partial)
    input_variables_without_partial = template.input_variables -- keys
    partial_variables = Map.merge(template.partial_variables, partial)

    {:ok,
     %LangChain.ProgramTemplate{
       template: template.template,
       input_variables: input_variables_without_partial,
       partial_variables: partial_variables
     }}
  end

  # in theory ProgramTemplates could be executed
  # by an interpreter or compiler, but for now we just
  # support elixir
  def execute(program_template) do
    case program_template.language do
      :elixir ->
        try do
          {result, _bindings} = Code.eval_string(program_template.template)
          {:ok, result}
        rescue
          e ->
            {:error, e}
        end
      _ ->
    end
  end

  def can_execute(program_template) do
    program_template.input_variables == []
  end
end
