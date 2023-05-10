# any huggingface-specific code should go in this file
defmodule LangChain.Providers.Huggingface do
  @moduledoc """
    A module for interacting with Huggingface's API
    Huggingface is a host for ML models that take in any data
    and return any data, it can be used for LLM, image generation, image parsing, sound, etc
  """

  defstruct model_name: "gpt2",
            max_new_tokens: 25,
            temperature: 0.5,
            top_k: nil,
            top_p: nil

  defimpl LangChain.LanguageModelProtocol, for: LangChain.Providers.Huggingface do
    @api_base_url "https://api-inference.huggingface.co/models"

    # get the Huggingface config from config.exs
    defp get_base(model) do
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

    def call(model, prompt) do
      body =
        Jason.encode!(%{
          "inputs" => prompt
        })

      base = get_base(model)

      case HTTPoison.post(base.url, body, base.headers) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          decoded_body = Jason.decode!(body)
          first_result = Enum.at(decoded_body, 0)
          Map.get(first_result, "generated_text")

        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, reason}
      end
    end

    # '{"inputs": {"past_user_inputs": ["Which movie is the best ?"],
    # "generated_responses": ["It is Die Hard for sure."], "text":"Can you explain why ?"}}' \
    def chat(model, chats) when is_list(chats) do
      json_input = prepare_input(chats)
      body = Jason.encode!(json_input)
      base = get_base(model)

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
