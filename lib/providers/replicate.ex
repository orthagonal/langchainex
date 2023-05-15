# any replicate-specific code should go in this file
defmodule LangChain.Providers.Replicate.LanguageModel do
  @moduledoc """
    A module for interacting with Replicate's API
    Replicate is a host for ML models that take in any data
    and return any data, it can be used for LLM, image generation, image parsing, sound, etc
  """
  require Logger

  defstruct provider: :replicate,
            # the model name isn't used by replicate but is used by LangChain
            model_name: "vicuna-13b",
            # the replicate model call needs the 'version' to find it
            version: "e6d469c2b11008bb0e446c3e9629232f9674581224536851272c54871f84076e",
            max_tokens: 2000,
            temperature: 0.1,
            n: 1

  defimpl LangChain.LanguageModelProtocol, for: LangChain.Providers.Replicate.LanguageModel do
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
      # try to make sure output is always a simple string
      if is_list(output) do
        output |> List.join()
      else
        output
      end
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
      # IO.puts("polling for prediction result")
      base = get_base(prediction_id, :poll)

      case HTTPoison.get(base.url, base.headers) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          response = Jason.decode!(body)
          # IO.inspect(response)

          case response["status"] do
            "succeeded" ->
              output =
                if is_list(response["output"]) do
                  # Join the output list into a single string
                  Enum.join(response["output"], " ")
                else
                  # If output is already a string, just return it as is
                  response["output"]
                end

              {:ok, output}

            result ->
              Process.sleep(@poll_interval)
              poll_for_prediction_result(prediction_id)
          end

        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, reason}
      end
    end

    # defp poll_for_prediction_result(prediction_id) do
    #   IO.puts("polling for prediction result")
    #   base = get_base(prediction_id, :poll)

    #   case HTTPoison.get(base.url, base.headers) do
    #     {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
    #       response = Jason.decode!(body)
    #       IO.inspect(response)

    #       case response["status"] do
    #         "succeeded" ->
    #           {:ok, response["output"]}

    #         result ->
    #           Process.sleep(@poll_interval)
    #           poll_for_prediction_result(prediction_id)
    #       end

    #     {:error, %HTTPoison.Error{reason: reason}} ->
    #       {:error, reason}
    #   end
    # end

    def chat(model, chats) when is_list(chats) do
      prompt =
        chats
        # Starts the index from 1
        |> Enum.with_index(1)
        |> Enum.map(fn {chat, index} ->
          role = Map.get(chat, :role, "")
          chat.text
          # "dialogprompt$#{index}: { text: '#{chat.text}'" <>
          #   if(role != "", do: ", role: '#{role}'", else: "") <> " }"
        end)
        |> Enum.join("\n")

      IO.inspect(prompt)

      call(model, prompt)
      |> handle_responses()
    end

    defp handle_responses(responses) when is_list(responses) do
      IO.inspect(responses)
      # if responses is a list of strings, just join the list and return
      case Enum.all?(responses, &is_binary/1) do
        true ->
          Enum.join(responses, " ")

        false ->
          Enum.map(responses, fn response ->
            case response do
              %{"translation_text" => text} -> text
              %{"generated_text" => text} -> text
              %{"conversation" => %{"generated_responses" => [text | _]}} -> text
              list when is_list(list) -> Enum.join(list, "\n")
              string when is_binary(string) -> string
              _ -> "Unknown response format"
            end
          end)
      end
    end

    defp handle_responses(responses) do
      case Enum.all?(responses, &match?({:ok, _}, &1)) do
        true -> {:ok, Enum.map(responses, fn {:ok, text} -> text end)}
        false -> {:error, "One or more responses failed"}
      end
    end
  end
end
