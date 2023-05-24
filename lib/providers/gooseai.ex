defmodule LangChain.Providers.GooseAi do
  @moduledoc """
  """
  # need to update this to scrape from page
  # @pricing_structure %{}

  # get the GooseAi config from config.exs
  def get_base(model) do
    {:ok, [api_key: api_key]} = Application.fetch_env(:langchainex, :goose_ai)

    url =
      case model.language_action do
        :generation -> "https://api.goose.ai/v1/engines/#{model.model_name}/completions"
        :classification -> ""
        true -> ""
      end

    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"}
    ]

    %{
      url: url,
      headers: headers
    }
  end

  def prepare_body(model, question) when is_binary(question) do
    case model.language_action do
      :generation ->
        %{
          prompt: question,
          max_tokens: model.max_token,
          temperature: model.temperature
        }
        |> Jason.encode!()

      :conversation ->
        %{} |> Jason.encode()
    end
  end

  def prepare_body(model, question) when is_list(question) do
    case model.language_action do
      :generation ->
        prompt =
          Enum.reduce(question, "", fn chat, acc ->
            acc <> "#{Map.get(chat, :role, "user")}: #{chat.text}\n"
          end)

        %{
          prompt: prompt,
          max_tokens: model.max_token,
          temperature: model.temperature
        }
        |> Jason.encode!()

      :conversation ->
        %{} |> Jason.encode!()
    end
  end

  def handle_response(model, body) do
    case model.language_action do
      :generation ->
        body
        |> Jason.decode!()
        |> Map.get("choices")
        |> List.first()
        |> Map.get("text")

      :conversation ->
        body
        |> Jason.decode!()
        |> Map.get("choices")
        |> List.first()
        |> Map.get("text")
    end
  end
end

defmodule LangChain.Providers.GooseAi.LanguageModel do
  @moduledoc """
    A module for interacting with GooseAi's API
    GooseAi is a host for ML models that take in any data
    and return any data, it can be used for LLM, image generation, image parsing, sound, etc
  """
  require Logger

  defstruct provider: :goose_ai,
        model_name: "gpt-j-6b",
        # model_name: "gpt-neo-20b",
        language_action: :generation,
        max_token: 400,
        temperature: 0.1

  defimpl LangChain.LanguageModelProtocol, for: LangChain.Providers.GooseAi.LanguageModel do
    def ask(model, question) do
      base = LangChain.Providers.GooseAi.get_base(model)
      body = LangChain.Providers.GooseAi.prepare_body(model, question)

      case HTTPoison.post(base.url, body, base.headers, [timeout: 50_000, recv_timeout: 60_000]) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          LangChain.Providers.GooseAi.handle_response(model, body)

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
