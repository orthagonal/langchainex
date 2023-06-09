defmodule LangChain.Providers.Cohere do
  @moduledoc """
  Cohere is a for-pay provider for ML models
  https://cohere.ai/docs
  """

  # get the Cohere config from config.exs
  def get_base(model) do
    {:ok, [api_key: api_key]} = Application.fetch_env(:langchainex, :cohere)

    url = "https://api.cohere.ai/v1/generate"

    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"},
      {"Accept", "application/json"}
    ]

    %{
      url: url,
      headers: headers
    }
  end

  def prepare_body(model, question) do
    %{
      prompt: question,
    #   "model": model.model_name,
    #   "max_tokens": model.max_token,
    #   "return_likelihoods": model.return_likelihoods,
    #   "truncate": model.truncate
    }
    |> Jason.encode!()
  end

  def handle_response(_model, body) do
    body
    |> Jason.decode!()
    |> Map.get("generated_text")
  end
end

defmodule LangChain.Providers.Cohere.LanguageModel do
  @moduledoc """
    A module for interacting with Cohere's API
    Cohere is a host for ML models that generate language based on given prompts.
  """
  require Logger

  defstruct provider: :cohere,
            model_name: "command",
            max_token: 20,
            temperature: 0.75, # ranges from 0.0 to 5.0
            k: 0 # limit number of tokens to consider to the top k tokens

  defimpl LangChain.LanguageModelProtocol, for: LangChain.Providers.Cohere.LanguageModel do
    def ask(model, question) do
      base = LangChain.Providers.Cohere.get_base(model)
      body = LangChain.Providers.Cohere.prepare_body(model, question)

      case HTTPoison.post(base.url, body, base.headers, timeout: 50_000, recv_timeout: 60_000) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          %{ "generations" => [%{ "text" => text }] } = body |> Jason.decode!()
          text

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
  end
end
