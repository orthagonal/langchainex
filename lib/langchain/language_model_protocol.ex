# Defines the shared interface that all LLMs must implement
# Remember, AI programs have two totally different knowledge domains:
# 1. _Program Knowledge Space_ is standard computery things like variable bindings, classes, functions
# 2. _AI Knowledge Space_ is semantic information in the conversation itself

# Functions in this interface only deal with AIKS, they know nothing about PKS and don't
# interact with PKS. PKS knows there are binaries and lists of binaries, it knows the
# size of those binaries and even the characters in them. But the semantic content
# of those binaries is only known in AIKS.

#
# if there is an error in the processing of the language model, that is returned as a string.
# an LLM must either implement these functions directly or if
# they don't support that langauge_type, must defer to another
# model that does
defprotocol LangChain.LanguageModelProtocol do
  defstruct provider: nil,
            model_name: nil,
            max_tokens: nil,
            temperature: nil,
            n: nil,
            options: nil

  # show a cumulative history of a conversation and then ask a question
  def converse(model, conversation)

  # ask a simple question and get a simple answer
  def ask(model, prompt)

  # todo:
  # inform the model of something
  # def elucidate(model, facts)
end

defmodule LangChain.LanguageModelLibrary do
  use GenServer

  # The state struct
  defmodule State do
    defstruct [
      :models,
      :lookup_tables,
      :load_fn,
      :query_fn
    ]
  end

  # Start function
  def start_link(init_state, load_fn, query_fn \\ nil) do
    GenServer.start_link(__MODULE__, {init_state, load_fn, query_fn})
  end

  # Init function
  def init({init_state, load_fn, query_fn}) do
    {:ok, %State{models: init_state, lookup_tables: %{}, load_fn: load_fn, query_fn: query_fn}}
  end

  # Handle call functions
  def handle_call({:list_models, query}, _from, state) do
    # Find models that match the query
    models =
      Enum.filter(state.models, fn model ->
        Enum.all?(query, fn {key, value} ->
          Map.get(model, key) == value
        end)
      end)

    {:reply, models, state}
  end

  def handle_call({:get_model_requirements, model_id}, _from, state) do
    # Find the model by id
    model =
      Enum.find(state.models, fn model ->
        model.provider == model_id.provider and
          (model.model_id == model_id.model_id or model.model_name == model_id.model_name)
      end)

    case model do
      nil ->
        # Handle case where model is not found
        {:reply, {:error, "Model not found"}, state}

      _ ->
        # Return model requirements
        {:reply, model, state}
    end
  end

  # Handle other calls
  def handle_call(_request, _from, state) do
    {:noreply, state}
  end
end
