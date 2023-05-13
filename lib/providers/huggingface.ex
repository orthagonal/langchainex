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
      IO.inspect(base)

      case HTTPoison.post(base.url, body, base.headers) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          # should just be list of dicts
          IO.inspect(body)
          decoded_body = Jason.decode!(body)

          IO.inspect(decoded_body)

        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, reason}
      end
    end

    def embed_query(provider, query) do
      embed_documents(provider, [query])
    end
  end
end

# any huggingface-specific code should go in this file
defmodule LangChain.Providers.Huggingface.LanguageModel do
  @moduledoc """
    A module for interacting with Huggingface's API
    Huggingface is a host for ML models that take in any data
    and return any data, it can be used for LLM, image generation, image parsing, sound, etc
  """
  alias LangChain.Providers.Huggingface

  defstruct model_name: "gpt2",
            max_new_tokens: 25,
            temperature: 0.5,
            top_k: nil,
            top_p: nil

  defimpl LangChain.LanguageModelProtocol, for: LangChain.Providers.Huggingface.LanguageModel do
    # call with a single input prompt
    def call(model, prompt) do
      body =
        Jason.encode!(%{
          "inputs" => prompt
        })

      base = Huggingface.get_base(model)

      case HTTPoison.post(base.url, body, base.headers) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          decoded_body = Jason.decode!(body)
          first_result = Enum.at(decoded_body, 0)
          Map.get(first_result, "generated_text")

        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, reason}
      end
    end

    # call with a list of input prompts
    def chat(model, chats) when is_list(chats) do
      json_input = prepare_input(chats)
      body = Jason.encode!(json_input)
      base = Huggingface.get_base(model)

      case HTTPoison.post(base.url, body, base.headers) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          decoded_body = Jason.decode!(body)
          first_result = Enum.at(decoded_body, 0)
          handle_response(first_result)

        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, reason}
      end
    end

    defp handle_response(response) do
      case response do
        {"conversation", %{"generated_responses" => generated_text}} ->
          generated_text

        {:error, _} = error ->
          error

        _ ->
          {:error, "Unexpected API response format"}
      end
    end

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
