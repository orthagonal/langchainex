defmodule LangChain.ChainLink do
  @compile {:nowarn_unused_function, [no_parse: 2]}
  @moduledoc """
    an individual chain_link in a language chain
    when called, a chainlink will
    1. fill in and submit an input prompt, then
    2. add the entire response to the responses list
    3. parse the response with the output_parser
    4. store any output
  """

  # a ChainLink input can be either a string, a prompttemplate or an entire chat chain
  @type input :: %LangChain.Chat{} | %LangChain.PromptTemplate{} | String.t()

  @derive Jason.Encoder
  defstruct name: "Void",
            # can be a string, a prompttemplate or an entire chat chain
            input: nil,
            # takes in the ChainLink and the list of all responses
            output_parser: &LangChain.ChainLink.no_parse/2,
            # from the model, pass your own output_parser to parse the output of your chat interactions
            # the actual response returned by the model
            raw_responses: [],
            # output should be a map of %{ variable: value } produced by output_parser
            output: %{},
            # list of errors that occurred during evaluation
            errors: [],
            # the pid of the LLM genserver that should process this chain
            process_with: nil,
            # the pid of the llm that processed this chain_link, nil if it has not been processed yet
            processed_by: nil

  @doc """
  calls the chain_link, filling in the input prompt and parsing the output
  """
  def call(
        %{input: %LangChain.PromptTemplate{} = prompt_template} = chain_link,
        llm_pid,
        previousValues
      ) do
    {:ok, evaluated_prompt} = LangChain.PromptTemplate.format(prompt_template, previousValues)

    case LangChain.LLM.call(llm_pid, evaluated_prompt) do
      {:ok, response} ->
        chain_link.output_parser.(chain_link, response)

      {:error, reason} ->
        chain_link |> Map.put(:errors, [reason])
    end
  end

  # when input is a simple string, note that this won't interpolate any variables
  def call(%{input: text_input} = chain_link, llm_pid, _previous_values)
      when is_binary(text_input) do
    case LangChain.LLM.call(llm_pid, text_input) do
      {:ok, response} ->
        %{
          chain_link
          | raw_responses: [response],
            output: %{text: response},
            processed_by: llm_pid
        }

      {:error, reason} ->
        chain_link |> Map.put(:errors, [reason])
    end
  end

  # you can define your own parser functions, but this is the default
  # the output of the ChainLink will be used as variables in the next link
  # by default the simple text response goes in the :text key
  def no_parse(chain_link, outputs \\ []) do
    case outputs do
      [] ->
        %{
          chain_link
          | raw_responses: outputs,
            output: %{text: outputs |> List.first() |> Map.get(:text)}
        }

      _ ->
        %{
          chain_link
          | raw_responses: outputs,
            output: %{text: outputs}
        }
    end
  end
end
