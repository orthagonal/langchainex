# any huggingface-specific code should go in this file

defmodule LangChain.Providers.Huggingface do
  @moduledoc """
  shared configuration for Huggingface API calls
  """
  @api_base_url "https://api-inference.huggingface.co/models"

  @doc """
  used by all the HF api calls, get the base url and headers for a given model
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
            max_new_tokens: 25,
            temperature: 0.1,
            top_k: nil,
            top_p: nil,
            polling_interval: 2000,
            fallback_chat_model: @fallback_chat_model

  defimpl LangChain.LanguageModelProtocol, for: LangChain.Providers.Huggingface.LanguageModel do
    def call(model, prompt) do
      try do
        request(model, prompt, :call)
      rescue
        _ ->
          "Huggingface API-based model #{model.model_name}: I had a technical malfunction trying to process #{prompt} "
      end
    end

    def chat(model, chats) when is_list(chats) do
      try do
        request(model, prepare_chat_input(chats), :chat)
      rescue
        _ ->
          "Huggingface API-based model #{model.model_name}: I had a technical malfunction trying to process these chats."
      end
    end

    # huggingface api can have a few different responses,
    # one is if the model is still loading
    # another is if the model you are calling is too big and needs dedicated hosting
    defp request(model, input, func_name) do
      base = Huggingface.get_base(model)

      case HTTPoison.post(base.url, input, base.headers,
             timeout: :infinity,
             recv_timeout: :infinity
           ) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          decoded_body = Jason.decode!(body)
          handle_response(decoded_body, func_name)

        {:ok, %HTTPoison.Response{status_code: 503, body: _body}} ->
          :timer.sleep(model.polling_interval)
          request(model, input, func_name)

        {:ok, %HTTPoison.Response{status_code: 403, body: _body}} ->
          IO.puts(
            "Model is too large to load, falling back to #{model.testfallback_chat_model.model_name}"
          )

          apply(__MODULE__, func_name, [model.testfallback_chat_model, input])

        {:error, %HTTPoison.Error{reason: reason}} ->
          reason

        e ->
          "Model #{model.provider} #{model.model_name}: I had a technical malfunction: #{IO.inspect(e)}"
      end
    end

    defp handle_response(decoded_body, :call) when is_list(decoded_body) do
      first_result = Enum.at(decoded_body, 0)
      handle_response(first_result)
    end

    defp handle_response(decoded_body, :call) do
      handle_response(decoded_body)
    end

    defp handle_response(decoded_body, :chat) do
      handle_chat_response(decoded_body)
    end

    defp handle_response(%{"generated_text" => generated_text}) do
      generated_text
    end

    defp handle_response(%{"translation_text" => translation_text}) do
      translation_text
    end

    defp handle_response(_), do: {:error, "Unexpected API response format"}

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

    # make a function that takes in list of %{ text, role } pairs and returns the following structure:
    # {
    #   inputs:
    #   {
    #     past_user_inputs: ["Which movie is the best ?"],
    #     generated_responses: ["It is Die Hard for sure."],
    #     text: "Can you explain why ?"
    #   }
    # }
    def prepare_chat_input(msgs) do
      msgs |> Enum.map_join("\n", fn msg -> msg.text end)
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
      # IO.puts(text)

      # Jason.encode!(%{
      #   inputs: %{
      #     past_user_inputs: past_user_inputs,
      #     generated_responses: generated_responses,
      #     text: text
      #   }
      # })
    end
  end
end
