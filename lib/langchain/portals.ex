defmodule LangChain.Portals do
  @moduledoc """
  A "portal" is a function that transports knowledge between the
  semantic and BEAM knowledge domains
  A standard langhchain 'prompt' is a 'portal' into the semantic domain
  Likewise a template that an LLM can use to fill in Elixir code is a 'portal' into the BEAM knowledge domain
  """

  @doc """
  a whirpool portal is a portal from semantic/AI knowledge domain into a VM's knowledge domain.
  This function will recursively ask the AI to update a snippet of Elixir source code (usally something very simply like scraping
  and decoding some JSON that was spit out by an LLM query) until that source code evaluates correctly with Code.eval_string.
  This usually only takes one iteration, since the LLM is shown both the failing code and the resulting error message,
  but I've seen it kind of....meander a little...before coming back.

  I don't try to make long elaborate elixir_code snippets, I keep them pretty simple.  Example:
    model = %LangChain.Providers.OpenAI.LanguageModel{}
    # notice this JSON is broken, so this will throw a SyntaxError the first time we eval_string it:
    elixir_code = "Jason.decode!("{\"a\": 1")"
    # whirlpool portal isn't fazed it will make up to 3 iterations to try to correct this code
    { value, bindings } = Courierlive.EmailParser.whirlpool_portal(model, elixir_code, max_steps: 3)
    # value will be this Elixir struct: %{"a" => 1}

  Options:
    :bindings - a map of bindings to use when evaluating the elixir_code
    :max_attempts - the maximum number of attempts to make before giving up
  """

  alias LangChain.PromptTemplate
  alias LangChain.LanguageModelProtocol

  def whirlpool_portal(model, elixir_code, options \\ []) do
    max_attempts = Keyword.get(options, :max_attempts, 10)
    cur_attempt = Keyword.get(options, :cur_attempt, 0)
    previous_code = Keyword.get(options, :previous_code, nil)
    original_prompt = Keyword.get(options, :prompt, "")
    original_temperature = Keyword.get(options, :original_temperature, model.temperature)

    current_temperature =
      if elixir_code == previous_code,
        do: min(1.0, model.temperature + 0.1),
        else: original_temperature

    model = %{model | temperature: current_temperature}
    if cur_attempt >= max_attempts do
      raise "whirlpool_portal failed after #{max_attempts} attempts"
    end

    bindings = Keyword.get(options, :bindings, [])
    IO.puts("******************")
    IO.puts("attempt #{cur_attempt} try to evaluate: \n#{elixir_code}\n")
    try do
      elixir_code
      |> Code.eval_string(bindings)
    rescue
      e ->
        error_message = Exception.format(:error, e)
        template = %PromptTemplate{
          template: """
            You are an Elixir programmer, this is the prompt you started with:
            #######
            <%= original_prompt %>
            #######
            This is the code you have written so far:
            #######
            <%= elixir_code %>
            #######
            When you evaluated it with Code.eval_string() you got this error: \"\"\"<%= error_message %>\"\"\".
            Fix the code so that it retains its meaning but doesn't crash when you evaluate it, ensure.
            data structures are being passed in the correct format. Only emit the corrected Elixir code to be evaluated, do not provide any commentary
            or explanation or surround the code with marking symbols or quotes.
          """,
          input_variables: [:original_prompt, :elixir_code, :error_message]
        }

        {:ok, query} =
          template
          |> PromptTemplate.format(%{
            error_message: error_message,
            elixir_code: elixir_code,
            original_prompt: original_prompt
          })

        next_iteration_of_elixir_code = LanguageModelProtocol.ask(model, query)

        whirlpool_portal(model, next_iteration_of_elixir_code,
          cur_attempt: cur_attempt + 1,
          max_attempts: max_attempts,
          bindings: bindings,
          previous_code: elixir_code,
          prompt: original_prompt,
          original_temperature: original_temperature
        )
    end
  end
end
