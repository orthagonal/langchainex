# any replicate-specific code should go in this file
defmodule LangChain.Providers.Replicate do
  @moduledoc """
    A module for interacting with Replicate's API
    Replicate is a host for ML models that take in any data
    and return any data, it can be used for LLM, image generation, image parsing, sound, etc
  """
  require Logger

  defstruct model_name: "alpaca",
            # the replicate model call uses the 'version'
            version: "latest",
            max_tokens: 25,
            temperature: 0.5,
            n: 1

  defimpl LangChain.LanguageModelProtocol, for: LangChain.Providers.Replicate do
    @api_base_url "https://api.replicate.com/v1/predictions"
    @poll_interval 1000

    # get the Replicate config from config.exs
    defp get_base(prediction_id, operation) do
      {
        :ok,
        [
          api_key: api_key,
          poll_interval: poll_interval
        ]
      } = Application.fetch_env(:langchainex, :replicate)

      case operation do
        :poll ->
          %{
            url: "#{@api_base_url}/#{prediction_id}",
            headers: [
              {"Authorization", "Token #{api_key}"},
              {"Content-Type", "application/json"}
            ],
            poll_interval: poll_interval
          }

        _ ->
          %{
            url: @api_base_url,
            headers: [
              {"Authorization", "Token #{api_key}"},
              {"Content-Type", "application/json"}
            ]
          }
      end
    end

    # with Replicate models first create a prediction, then you poll the API call
    # until the prediction is complete, then you get the output
    def call(model, prompt) do
      {:ok, prediction_id} = create_prediction(model, prompt)
      Logger.debug(" got back prediction " <> prediction_id)
      {:ok, output} = poll_for_prediction_result(prediction_id)
      output
    end

    defp create_prediction(model, input) do
      body =
        Jason.encode!(%{
          "version" => model.version,
          "input" => %{"text" => input, "prompt" => input}
        })

      base = get_base(nil, :predict)

      case HTTPoison.post(base.url, body, base.headers) do
        {:ok, %HTTPoison.Response{status_code: 201, body: body}} ->
          {:ok, Jason.decode!(body)["id"]}

        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, reason}
      end
    end

    defp poll_for_prediction_result(prediction_id) do
      base = get_base(prediction_id, :poll)

      case HTTPoison.get(base.url, base.headers) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          response = Jason.decode!(body)

          case response["status"] do
            "succeeded" ->
              {:ok, response["output"]}

            _ ->
              Process.sleep(@poll_interval)
              poll_for_prediction_result(prediction_id)
          end

        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, reason}
      end
    end

    def chat(model, chats) when is_list(chats) do
      chats
      |> Enum.map(fn chat ->
        call(model, chat.text)
      end)
      |> handle_responses()
    end

    defp handle_responses(responses) do
      case Enum.all?(responses, &match?({:ok, _}, &1)) do
        true -> {:ok, Enum.map(responses, fn {:ok, text} -> text end)}
        false -> {:error, "One or more responses failed"}
      end
    end
  end
end
