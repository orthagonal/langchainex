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
    model_name: "gpt2",
    max_new_tokens: 25,
    temperature: 0.5,
    top_k: nil,
    top_p: nil,
    polling_interval: 2000
  }

  defstruct model_name: "gpt2",
            max_new_tokens: 25,
            temperature: 0.5,
            top_k: nil,
            top_p: nil,
            polling_interval: 2000

  defimpl LangChain.LanguageModelProtocol, for: LangChain.Providers.Huggingface.LanguageModel do
    def call(model, prompt) do
      request(model, prompt, :call)
    end

    def chat(model, chats) when is_list(chats) do
      request(model, prepare_input(chats), :chat)
    end

    # huggingface api can have a few different responses,
    # one is if the model is still loading
    # another is if the model you are calling is too big and needs dedicated hosting
    defp request(model, input, func_name) do
      base = Huggingface.get_base(model)
      body = Jason.encode!(%{"inputs" => input})

      IO.puts("Requesting: #{base.url} with body: #{body}")

      case HTTPoison.post(base.url, body, base.headers) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          IO.puts("Received 200 response: #{body}")
          decoded_body = Jason.decode!(body)
          handle_response(decoded_body, func_name)

        {:ok, %HTTPoison.Response{status_code: 503, body: _body}} ->
          IO.puts("Received 503 response")
          :timer.sleep(model.polling_interval)
          request(model, input, func_name)

        {:ok, %HTTPoison.Response{status_code: 403, body: _body}} ->
          IO.puts("Received 403 response")

          fallback_model = %LangChain.Providers.Huggingface.LanguageModel{
            model_name: "gpt2",
            max_new_tokens: 25,
            temperature: 0.5,
            top_k: nil,
            top_p: nil,
            polling_interval: 2000
          }

          IO.puts("Model is too large to load, falling back to #{fallback_model.model_name}")
          apply(__MODULE__, func_name, [fallback_model, input])

        {:error, %HTTPoison.Error{reason: reason}} ->
          IO.puts("Received error: #{reason}")
          {:error, reason}
      end
    end

    defp handle_response(decoded_body, :call) when is_list(decoded_body) do
      first_result = Enum.at(decoded_body, 0)
      handle_response(first_result)
    end

    defp handle_response(decoded_body, :call) do
      handle_response(decoded_body)
    end

    defp handle_response(%{"generated_text" => generated_text}) do
      generated_text
    end

    defp handle_response(%{"translation_text" => translation_text}) do
      translation_text
    end

    defp handle_response(%{"conversation" => %{"generated_responses" => responses}}) do
      List.first(responses)
    end

    defp handle_response(_), do: {:error, "Unexpected API response format"}

    def prepare_input(msgs) do
      {past_user_inputs, generated_responses} =
        Enum.reduce(msgs, {[], []}, fn msg, {user_inputs, responses} ->
          role = Map.get(msg, :role, "user")

          case role do
            "user" -> {[msg.text | user_inputs], responses}
            _ -> {user_inputs, [msg.text | responses]}
          end
        end)

      last_text = List.last(msgs).text

      %{
        "inputs" => %{
          "past_user_inputs" => Enum.reverse(past_user_inputs),
          "generated_responses" => Enum.reverse(generated_responses),
          "text" => last_text
        }
      }
      |> Jason.encode!()
    end
  end
end
