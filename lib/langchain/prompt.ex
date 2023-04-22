# a PromptTemplate is just a normal string template
# you can pass it a set of values and it will interpolate them
# you can also partially evaluate the template by calling the partial/2 function
# inputVariables will always be a list of variables that still need to be specified
defmodule LangChain.PromptTemplate do
  # template is the template as a string
  # inputVariables is a list of variables that need to be specified for that template
  # partialVariables is a map of variables that have already been specified and can be applied to the template
  # add defaults
  # src currently can be one of :user, :system, :ai, :generic
  # though you could add more
  @derive Jason.Encoder
  defstruct [template: "", inputVariables: [], partialVariables: %{}, src: :user]

  # converts to eex and then interpolates the values+partialVariables
  # eex needs values and partialVariables to be specified as a map with atom keys
  def format(template, values) do
    # env is a keyword list merging values and partials and convert
    env = Map.merge(values, template.partialVariables)
      |> Map.to_list()
      |> Enum.map(fn {k, v} -> {k, v}
        if is_function(v) do
          case  v.() do
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

  # partially apply the variables in 'partial' to the partialVariables and
  # remove them from the inputVariables
  def partial(template, partial) do
    keys = Map.keys(partial)
    inputVariablesWithoutPartial = template.inputVariables -- keys
    partialVariables = Map.merge(template.partialVariables, partial)
    {:ok, %LangChain.PromptTemplate{
      template: template.template,
      inputVariables: inputVariablesWithoutPartial,
      partialVariables: partialVariables
    }}
  end

  # defp serialize_prompt_message(prompt_message) do
  #   # Implement the serialization logic for the specific prompt message type here.
  #   # You might need to pattern match or use a separate function for each message type.
  # end
end
