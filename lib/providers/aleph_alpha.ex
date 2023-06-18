defmodule LangChain.Providers.AlephAlpha.LanguageModel do
  @moduledoc """
    A module for interacting with Aleph Alpha's API
    Aleph Alpha hosts ML models that take in any data
    and return any data. It can be used for language model completions.
    Aleph Alpha is a for-pay provider for ML models
    https://aleph-alpha.com/docs/api/
  """
  require Logger
  alias LangChain.Providers.AlephAlpha

  defstruct provider: :aleph_alpha,
            model_name: "luminous-base",
            max_token: 400

  defimpl LangChain.LanguageModelProtocol, for: LangChain.Providers.AlephAlpha.LanguageModel do
    def ask(model, question) do
      base = get_base(model)
      body = prepare_body(model, question)

      case HTTPoison.post(base.url, body, base.headers, timeout: 50_000, recv_timeout: 60_000) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          LangChain.Providers.AlephAlpha.handle_response(model, body)

        {:ok, %HTTPoison.Response{status_code: _status_code, body: body}} ->
          # credo:disable-for-next-line
          IO.inspect(body)

          "I experienced a technical malfunction trying to run #{model.model_name}. Please try again later."

        {:error, %HTTPoison.Error{reason: reason}} ->
          # credo:disable-for-next-line
          IO.inspect(reason)

          "I experienced a technical malfunction trying to run #{model.model_name}. Please try again later."
      end
    end

    defp get_base(model) do
      {:ok, [api_key: api_key]} = Application.fetch_env(:langchainex, :aleph_alpha)

      url = "https://api.aleph-alpha.com/complete"

      headers = [
        {"Authorization", "Bearer #{api_key}"},
        {"Content-Type", "application/json"}
      ]

      %{
        url: url,
        headers: headers
      }
    end

    defp prepare_body(model, question) when is_binary(question) do
      %{
        model: model.model_name,
        prompt: question,
        maximum_tokens: model.max_token
      }
      |> Jason.encode!()
    end

    defp prepare_body(model, question) when is_list(question) do
      # Create the prompt by joining the messages in the list
      prompt =
        Enum.reduce(question, "", fn item, acc ->
          role = "role:" <> Map.get(item, :role, "user")
          text = Map.get(item, :text, "")
          acc <> "\n#{role}: #{text}"
        end)

      %{
        model: model.model_name,
        prompt: prompt,
        maximum_tokens: model.max_token
      }
      |> Jason.encode!()
    end

    defp handle_response(model, body) do
      body
      |> Jason.decode!()
      |> Map.get("completions", [])
      |> List.first()
      |> Map.get("completion", "I did not get a response")
    end
  end
end
