defmodule LangChain.PromptTemplate do
  @moduledoc """
  a PromptTemplate is just a normal string template,
  you can pass it a set of values and it will interpolate them.
  You can also partially evaluate the template by calling the partial/2 function
  input_variables will contain the list of variables that still need to be specified to
  complete the template.
  """

  @derive Jason.Encoder
  defstruct [
    template: "", # template is a string
    input_variables: [], # input_variables is a list of variables that need to be specified for that template
    partial_variables: %{}, # partial_variables is a map of variables that have already been specified and can be applied to the template
    src: :user # src is the source of the message, currently one of :user, :system, :ai, :generic
  ]

  @doc """
  converts to eex and then interpolates the values+partial_variables.
  (eex wants values and partial_variables to be specified as a map with atomic keys)
  """
  def format(template, values) do
    # env is a keyword list merging values and partials and convert
    env = Map.merge(values, template.partial_variables)
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

  @doc """
  partially apply the variables in 'partial' to the partial_variables and
  remove them from the input_variables
  """
  def partial(template, partial) do
    keys = Map.keys(partial)
    input_variables_without_partial = template.input_variables -- keys
    partial_variables = Map.merge(template.partial_variables, partial)
    {:ok, %LangChain.PromptTemplate{
      template: template.template,
      input_variables: input_variables_without_partial,
      partial_variables: partial_variables
    }}
  end

  # defp serialize_prompt_message(prompt_message) do
  #   # Implement the serialization logic for the specific prompt message type here.
  #   # You might need to pattern match or use a separate function for each message type.
  # end
end
