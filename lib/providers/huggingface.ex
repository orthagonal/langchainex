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
    generation: """
    { inputs: "
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
    " }
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
    table_question_answering: """
    { "inputs": {
      "query": "<%= input.query %>",
      "table": <%= input.table |> Jason.encode!() %>
    } }
    """,
    sentence_similarity: """
    { inputs: {
      source_sentence: "<%= input.source_sentence %>",
      sentences: <%= input.sentences |> Enum.join(",") |> Jason.encode!() %>
    } }
    """,
    # NER named entity recognition is basically translation from one language to another
    text_translation: """
    { inputs: "<%= input %>" }
    """,
    zero_shot_classification: """
    { inputs: "<%= input.text %>", parameters: {candidate_labels: <%= input.labels |> Enum.join(",") |> Jason.encode!() %>} }
    """,
    fill_mask: """
    { inputs: "<%= input %>" }
    """,
    # audio input models
    automatic_speech_recognition: """
    { audio_file: "<%= input.audio_file %>" }
    """,
    audio_classification: """
    { audio_file: "<%= input.audio_file %>" }
    """,
    # video input models
    # image_classification: """
    # { image_file: "<%= input.image_file %>" }
    # """,
    # object_detection: """
    # { image_file: "<%= input.image_file %>" }
    # """,
    # image_segmentation: """
    # { image_file: "<%= input.image_file %>" }
    # """
  }
  def get_template_body_for_action(model) do
    Map.get(@request_templates, model.language_action)
  end

  # default hf models for each action
  @default_models %{
    conversation: "microsoft/DialoGPT-large",
    generation: "EleutherAI/gpt-neo-2.7B",
    table_question_answering: "google/tapas-base-finetuned-wtq",
    sentence_similarity: "sentence-transformers/all-MiniLM-L6-v2",
    text_translation: "Helsinki-NLP/opus-mt-ru-en",
    zero_shot_classification: "facebook/bart-large-mnli",
    # audio models for the same model type
    automatic_speech_recognition: "facebook/wav2vec2-base-960h",
    audio_classification: "superb/hubert-large-superb-er",
    image_classification: "google/vit-base-patch16-224",
    object_detection: "facebook/detr-resnet-50",
    image_segmentation: "facebook/detr-resnet-50-panoptic"
  }

  # this function will now provide the default model if none is specified
  def get_model_for_action(action, model_name \\ nil) do
    IO.puts "get it"
    IO.puts "get it"
    IO.puts "get it"
    IO.inspect action
    IO.inspect model_name
    if is_nil(model_name) do
      Map.get(@default_models, action)
    else
      model_name
    end
  end

  @doc """
  finds the right input format for this model/input
  and returns it as a http request body in string form
  """
  def prepare_input(model, input) do
    cond do
      model.language_action == :generation and is_binary(input) ->
        %{
          inputs: input
        }
        |> Jason.encode!()

      model.language_action == :generation ->
        %{
          inputs: input |> Enum.join(" ")
        }
        |> Jason.encode()

      model.language_action == :table_question_answering ->
        template = get_template_body_for_action(model)
        try do
          atom_input = %{
            :query => input["query"] || input[:query],
            :table => input["table"] || input[:table]
          }
          EEx.eval_string(template, input: atom_input)
        rescue
          error -> error
        end
      true ->
        template = get_template_body_for_action(model)

        try do
          EEx.eval_string(template, input: input)
        rescue
          error -> error
        end
    end
  end



  # parsers for parsing the response from the API
  # this is also an example of "transforming program knowledge space into AI knowledge space"

  @doc """
  finds the matching output format for this model/input
  and returns it as a string
  """
  def handle_response(model, response) do
    IO.inspect model.language_action
    case model.language_action do
      :generation -> handle_generation(response)
      :conversation -> handle_conversation(response)
      :text_translation -> handle_generation(response)
      # :table_question_answering -> handle_table_question_answering(response)
      # :sentence_similarity -> handle_sentence_similarity(response)
      # :zero_shot_classification -> handle_zero_shot_classification(response)
      # :fill_mask -> handle_fill_mask(response)
      # :automatic_speech_recognition -> handle_automatic_speech_recognition(response)
      # :audio_classification -> handle_audio_classification(response)
      :image_classification -> handle_image_classification(response)
      # :object_detection -> handle_object_detection(response)
      # :image_segmentation -> handle_image_segmentation(response)
      _ -> "Unsupported action"
    end
  end

  def handle_image_classification(list_of_id) do
    list_of_id |> Enum.map_join(", ", fn id -> Map.get(id, "label", "") end)
  end

  def handle_generation([%{"generated_text" => text} | _tail]) do
    text
  end

  def handle_generation(response) when is_binary(response) do
    response
  end

  def handle_generation(responses) when is_list(responses) do
    case Enum.at(responses, 0) do
      %{"generated_text" => _} ->
        responses
        |> Enum.map_join(" ", fn %{"generated_text" => text} -> text end)

      %{"translation_text" => _} ->
        responses
        |> Enum.map_join(" ", fn %{"translation_text" => text} -> text end)

      response when is_binary(response) ->
        Enum.join(responses, " ")

      response when is_float(response) ->
        responses
        |> Enum.map_join(", ", &Float.to_string/1)

      _ ->
        "Unsupported response format"
    end
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
        |> Enum.map_join(" ", fn %{"generated_text" => text} -> text end)

      response when is_binary(response) ->
        Enum.join(responses, " ")

      response when is_float(response) ->
        responses
        |> Enum.map_join(", ", &Float.to_string/1)

      _res ->
        "Unsupported response format"
    end
  end

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
    # if model_name is nil, use the default model for this action
    model_name = get_model_for_action(model.language_action, model.model_name)
    %{
      url: "#{@api_base_url}/#{model_name}",
      headers: [
        {"Authorization", "Bearer #{api_key}"},
        {"Content-Type", "application/json"}
      ]
    }
  end

  # audio uses octet stream
  def get_base_audio(model) do
    {
      :ok,
      [
        api_key: api_key
      ]
    } = Application.fetch_env(:langchainex, :huggingface)
    model_name = get_model_for_action(model.language_action, model.model_name)
    %{
      url: "#{@api_base_url}/#{model_name}",
      headers: [
        {"Authorization", "Bearer #{api_key}"},
        {"Content-Type", "application/octet-stream"}
      ]
    }
  end

  # video uses octet stream
  def get_base_video(model) do
    {
      :ok,
      [
        api_key: api_key
      ]
    } = Application.fetch_env(:langchainex, :huggingface)
    model_name = get_model_for_action(model.language_action, model.model_name)
    %{
      url: "#{@api_base_url}/#{model_name}",
      headers: [
        {"Authorization", "Bearer #{api_key}"},
        {"Content-Type", "application/octet-stream"}
      ]
    }
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
    model_name: nil,  # default to nil
    language_action: :conversation,
    max_new_tokens: 25,
    temperature: 0.5,
    top_k: nil,
    top_p: nil,
    polling_interval: 2000
  }

  defstruct provider: :huggingface,
            model_name: nil,
            language_action: :conversation,
            max_new_tokens: 25,
            temperature: 0.1,
            top_k: nil,
            top_p: nil,
            polling_interval: 2000,
            fallback_chat_model: @fallback_chat_model

  def new(language_action, model_name \\ nil) do
    model_name = Huggingface.get_model_for_action(language_action, model_name)
    %__MODULE__{model_name: model_name, language_action: language_action}
  end

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
          IO.puts("Model is still loading, trying again")
          request(model, input)

        {:ok, %HTTPoison.Response{status_code: 403, body: _body}} ->
          IO.puts(
            "Model is too large to load, falling back to #{model.testfallback_chat_model.model_name}"
          )

          # fallback is a chat model:
          apply(__MODULE__, :chat, [model.testfallback_chat_model, input])

        {:error, %HTTPoison.Error{reason: reason}} ->
          IO.puts("poison error")
          reason

        _e ->
          IO.puts "got error"
          IO.inspect _e
          "Model #{model.provider} #{model.model_name}: I had a technical malfunction"
      end
    end
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

defmodule LangChain.Providers.Huggingface.AudioModel do
  @moduledoc"""
  Audio models with huggingface
  """
  alias LangChain.Providers.Huggingface

  defstruct provider: :huggingface,
            model_name: nil,
            language_action: :automatic_speech_recognition,
            polling_interval: 2000

  def new(language_action, model_name \\ nil) do
    model_name = Huggingface.get_model_for_action(language_action, model_name)
    %__MODULE__{model_name: model_name, language_action: language_action}
  end

  defimpl LangChain.AudioModelProtocol, for: LangChain.Providers.Huggingface.AudioModel do
    def stream(model, audio_stream) do
    end

    def speak(model, audio_data) do
      base = LangChain.Providers.Huggingface.get_base_audio(model)

      case HTTPoison.post(base.url, audio_data, base.headers,
             timeout: :infinity,
             recv_timeout: :infinity
           ) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          decoded_body = Jason.decode!(body)
          decoded_body["text"]

        {:ok, %HTTPoison.Response{status_code: 503, body: _body}} ->
          :timer.sleep(model.polling_interval)
          IO.puts("Model is still loading, trying again")
          speak(model, audio_data)

        {:ok, %HTTPoison.Response{status_code: 403, body: _body}} ->
          IO.puts("Model is too large to load.")

        {:error, %HTTPoison.Error{reason: reason}} ->
          IO.puts("poison error")
          reason

        _e ->
          "Model #{model.provider} #{model.model_name}: I had a technical malfunction"
      end
    end
  end
end

defmodule LangChain.Providers.Huggingface.ImageModel do
  @moduledoc """
  Image models with huggingface
  """
  alias LangChain.Providers.Huggingface

  defstruct provider: :huggingface,
            model_name: nil,  # default to nil
            language_action: :image_classification,
            polling_interval: 2000

  def new(language_action, model_name \\ nil) do
    model_name = Huggingface.get_model_for_action(language_action, model_name)
    %__MODULE__{model_name: model_name, language_action: language_action}
  end

  defimpl LangChain.ImageModelProtocol, for: LangChain.Providers.Huggingface.ImageModel do
    def describe(image_model, image_data) do
      request(image_model, image_data)
    end

    def detect_objects(image_model, image_path) do
      # call Huggingface API to detect objects in the image
    end
    defp request(model, input) do
      base = Huggingface.get_base_video(model)
      case HTTPoison.post(base.url, input, base.headers,
             timeout: :infinity,
             recv_timeout: :infinity
           ) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          decoded_body = Jason.decode!(body)
          LangChain.Providers.Huggingface.handle_response(model, decoded_body)

        {:ok, %HTTPoison.Response{status_code: 503, body: _body}} ->
          :timer.sleep(model.polling_interval)
          IO.puts("Model is still loading, trying again")
          request(model, input)

        {:ok, %HTTPoison.Response{status_code: 403, body: _body}} ->
          IO.puts(
            "Model is too large to load, falling back to #{model.testfallback_chat_model.model_name}"
          )

          # fallback is a chat model:
          apply(__MODULE__, :chat, [model.testfallback_chat_model, input])

        {:error, %HTTPoison.Error{reason: reason}} ->
          IO.puts("poison error")
          reason

        _e ->
          IO.puts "got error"
          IO.inspect _e
          "Model #{model.provider} #{model.model_name}: I had a technical malfunction"
      end
    end

  end

end
