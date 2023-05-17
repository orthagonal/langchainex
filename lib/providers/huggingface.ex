# any huggingface-specific code should go in this file
defmodule LangChain.Providers.Huggingface do
  @moduledoc """
  shared configuration for Huggingface API calls
  """
  @api_base_url "https://api-inference.huggingface.co/models"

  # payload templates for POSTing API requests
  # this is an example of "transforming AI knowledge space into program knowledge space"
  @request_templates %{
    conversation: """
    <%= cond do %>
    <% is_list(input) and is_map(Enum.at(input, 0)) -> %>
      <%= input
      |> Enum.map(fn %{text: text} -> text end)
      |> Enum.join(" ")
    %>
    <% is_list(input) -> %> <%= Enum.join(input, " ") %>
    <% is_binary(input) -> %> <%= input %>
    <% true -> %> <%= "Input is neither a list nor a string" %>
    <% end %>
    """,
    fill_mask: """
    """,
    generation: """
    <%= cond do %>
    <% is_list(input) and is_map(Enum.at(input, 0)) -> %>
      <%= input
      |> Enum.map(fn %{text: text} -> text end)
      |> Enum.join(" ")
    %>
    <% is_list(input) -> %> <%= Enum.join(input, " ") %>
    <% is_binary(input) -> %> <%= input %>
    <% true -> %> <%= "Input is neither a list nor a string" %>
    <% end %>
    """,
    # input for question answering is just a string
    question_answering: """
    <%= cond do %>
    <% is_list(input) and is_map(Enum.at(input, 0)) -> %>
      <%= input
      |> Enum.map(fn %{text: text} -> text end)
      |> Enum.join(" ")
    %>
    <% is_list(input) -> %> <%= Enum.join(input, " ") %>
    <% is_binary(input) -> %> <%= input %>
    <% true -> %> <%= "Input is neither a list nor a string" %>
    <% end %>
    """,
    text_classification: """
    """,
    token_classification: """
    """,
    zero_shot_classification: """
    """
  }
  def get_template_body_for_action(model) do
    Map.get(@request_templates, model.language_action)
  end

  @doc """
  finds the right input format for this model/input
  and returns it as a http request body in string form
  """
  def prepare_input(model, input) do
    template = get_template_body_for_action(model)

    try do
      processed_template = EEx.eval_string(template, input: input)
      # processed_template |> Jason.encode!()
    rescue
      error -> IO.inspect(error)
    end
  end

  # parsers for parsing the response from the API
  # this is also an example of "transforming program knowledge space into AI knowledge space"

  @doc """
  finds the matching output format for this model/input
  and returns it as a string
  """
  @doc """
  finds the matching output format for this model/input
  and returns it as a string
  """
  def handle_response(model, response) do
    handle_conversation(response)
  end

  # Helper functions to handle conversation responses
  defp handle_conversation(%{"conversation" => %{"generated_responses" => responses}}) do
    responses
    |> Enum.join(" ")
  end

  defp handle_conversation(responses) when is_list(responses) do
    case Enum.at(responses, 0) do
      %{"generated_text" => _} ->
        responses
        |> Enum.map(fn %{"generated_text" => text} -> text end)
        |> Enum.join(" ")

      response when is_binary(response) ->
        Enum.join(responses, " ")

      response when is_float(response) ->
        responses
        |> Enum.map(&Float.to_string/1)
        |> Enum.join(", ")

      res ->
        "Unsupported response format"
    end
  end

  # defp oldhr(decoded_body, :question_answering) when is_list(decoded_body) do
  #   first_result = Enum.at(decoded_body, 0)
  #   oldhr(first_result)
  # end
  # defp oldhr(decoded_body, :question_answering) do
  #   oldhr(decoded_body)
  # end
  # defp oldhr(decoded_body, :chat) do
  #   handle_chat_response(decoded_body)
  # end
  # defp oldhr(%{"translation_text" => translation_text}) do
  #   translation_text
  # end
  # defp oldhr(_), do: {:error, "Unexpected API response format"}

  @known_conversation_models [
    "facebook/blenderbot-400M-distill"
  ]
  @doc """
  used by all the HF api calls, get the base URL and HTTP headers for a given model
  """
  def get_base(model) do
    {
      :ok,
      [
        api_key: api_key
      ]
    } = Application.fetch_env(:langchainex, :huggingface)

    %{
      url: "#{@api_base_url}/#{model.model_name}",
      headers: [
        {"Authorization", "Bearer #{api_key}"},
        {"Content-Type", "application/json"}
      ]
    }
  end

  @doc """
  translate whatever input (string, list of %{ role, text } to the right payload format
  for the given language action
  """
  def translate_payload_for_language_action(input, language_action) do
  end
end

defmodule LangChain.Providers.Huggingface.LanguageModel do
  @moduledoc """
    A module for interacting with Huggingface's API
    Huggingface is a host for ML models that take in any data
    and return any data, it can be used for LLM, image generation, image parsing, sound, etc
  """
  alias LangChain.Providers.Huggingface

  @fallback_chat_model %{
    provider: :huggingface,
    model_name: "google/flan-t5-small",
    max_new_tokens: 25,
    temperature: 0.5,
    top_k: nil,
    top_p: nil,
    polling_interval: 2000
  }

  defstruct provider: :huggingface,
            model_name: "microsoft/DialoGPT-large",
            language_action: :conversation,
            max_new_tokens: 25,
            temperature: 0.1,
            top_k: nil,
            top_p: nil,
            polling_interval: 2000,
            fallback_chat_model: @fallback_chat_model

  defimpl LangChain.LanguageModelProtocol, for: LangChain.Providers.Huggingface.LanguageModel do
    def ask(model, prompt) do
      try do
        request(model, LangChain.Providers.Huggingface.prepare_input(model, prompt))
      rescue
        error ->
          # str = error |> Exception.format(:error) |> IO.iodata_to_binary()
          "Huggingface API-based model #{model.model_name}: I had a technical malfunction trying to process #{prompt} "
      end
    end

    # huggingface api can have a few different responses,
    # one is if the model is still loading
    # another is if the model you are calling is too big and needs dedicated hosting
    defp request(model, input) do
      base = Huggingface.get_base(model)

      case HTTPoison.post(base.url, input, base.headers,
             timeout: :infinity,
             recv_timeout: :infinity
           ) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          decoded_body = Jason.decode!(body)
          LangChain.Providers.Huggingface.handle_response(model, decoded_body)

        {:ok, %HTTPoison.Response{status_code: 503, body: _body}} ->
          :timer.sleep(model.polling_interval)
          IO.inspect("Model is still loading, trying again")
          request(model, input)

        {:ok, %HTTPoison.Response{status_code: 403, body: _body}} ->
          IO.puts(
            "Model is too large to load, falling back to #{model.testfallback_chat_model.model_name}"
          )

          # fallback is a chat model:
          apply(__MODULE__, :chat, [model.testfallback_chat_model, input])

        {:error, %HTTPoison.Error{reason: reason}} ->
          IO.inspect(reason)
          reason

        e ->
          "Model #{model.provider} #{model.model_name}: I had a technical malfunction"
      end
    end

    defp handle_chat_response(decoded_body) when is_list(decoded_body) do
      Enum.map_join(decoded_body, "\n", fn %{"generated_text" => inner_json_string} ->
        inner_json_string
      end)
    end

    defp handle_chat_response(decoded_body) when is_map(decoded_body) do
      cond do
        decoded_body["generated_text"] ->
          decoded_body["generated_text"]

        decoded_body["translation_text"] ->
          decoded_body["translation_text"]

        decoded_body["text"] ->
          decoded_body["text"]

        true ->
          "Unexpected API response format"
      end
    end

    # {
    #   inputs:
    #   {
    #     past_user_inputs: ["Which movie is the best ?"],
    #     generated_responses: ["It is Die Hard for sure."],
    #     text: "Can you explain why ?"
    #   }
    # }
    # def prepare_input(msgs) do
    #   msgs |> Enum.map_join("\n", fn msg -> msg.text end)
    # get all but the last item in the list:
    # history = msgs |> List.delete_at(-1)

    # past_user_inputs =
    #   history
    #   |> Enum.filter(fn msg -> msg.role == "user" end)
    #   |> Enum.map(fn msg -> msg.text end)

    # generated_responses =
    #   history
    #   |> Enum.filter(fn msg -> msg.role != "user" end)
    #   |> Enum.map(fn msg -> msg.text end)

    # text = msgs |> List.last() |> Map.get(:text)

    # package = %{
    #   conversation: %{
    #     past_user_inputs: past_user_inputs,
    #     generated_responses: generated_responses,
    #     text: text,
    #     warnings: []
    #   }
    # }

    # IO.inspect(package)
    # Jason.encode!(package)
    # end
  end
end

defmodule LangChain.Providers.Huggingface.Embedder do
  @moduledoc """
  When you want to use the huggingface API to embed documents
  Embedding will transform documents into vectors of numbers that you can then feed into a neural network
  The embedding provider must match the input size of the model and use the same encoding scheme.
  Use Sentence Transformer modles like
  """

  alias LangChain.Providers.Huggingface
  defstruct model_name: "gpt2"

  defimpl LangChain.EmbedderProtocol do
    def embed_documents(provider, documents) do
      body =
        Jason.encode!(%{
          inputs: documents,
          # see https://huggingface.co/docs/api-inference/detailed_parameters#feature-extraction-task for options
          use_cache: true,
          wait_for_model: false
        })

      base = Huggingface.get_base(provider)

      case HTTPoison.post(base.url, body, base.headers) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          # should just be list of dicts
          Jason.decode!(body)

        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, reason}
      end
    end

    def embed_query(provider, query) do
      embed_documents(provider, [query])
    end
  end
end
