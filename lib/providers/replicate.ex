# any replicate-specific code should go in this file

defmodule LangChain.Providers.Replicate do
  @moduledoc """
  Replicate's pricing structure is based on what hardware you use
  and how long you use it.  More expensive hardware runs faster

  Replicate's Pricing Structure
  # CPU
  # $0.0002 per second
  # (or, $0.012 per minute)

  # 4x CPU
  # 8GB RAM

  # Nvidia T4 GPU
  # $0.00055 per second
  # (or, $0.033 per minute)

  # 4x CPU
  # 16GB GPU RAM
  # 8GB RAM

  # Nvidia A100 40GB GPU
  # $0.0023 per second
  # (or, $0.138 per minute)

  """

  @pricing_structure %{
    cpu: %{
      dollars_per_second: 0.0002,
      dollars_per_token: nil
    },
    t4: %{
      dollars_per_second: 0.00055,
      dollars_per_token: nil
    },
    a100: %{
      dollars_per_second: 0.0023,
      dollars_per_token: nil
    }
  }

  @doc """
  Used to report the price of a response from Replicate
  """
  def report_price(%{"status" => "succeeded"} = response) do
    try do
      # just assume it's a cpu for right now:
      pricing_structure = @pricing_structure[:cpu]
      %{"metrics" => %{"predict_time" => predict_time}} = response

      total_price =
        (pricing_structure.dollars_per_second * predict_time)
        |> :erlang.float_to_binary(decimals: 8)

      LangChain.Agents.TheAccountant.store(%{
        provider: :replicate,
        total_price: total_price
      })

      # IO.puts("Replicate #{predict_time} seconds cost $#{total_price}")
    rescue
      error -> error
    end
  end

  # optional function for the one above
  # credo:disable-for-next-line
  def report_price(_response) do
  end
end

defmodule LangChain.Providers.Replicate.LanguageModel do
  @moduledoc """
    A module for interacting with Replicate's API
    Replicate is a host for ML models that take in any data
    and return any data, it can be used for LLM, image generation, image parsing, sound, etc
  """
  require Logger

  defstruct provider: :replicate,
            # the model name isn't used by replicate but is used by LangChain
            model_name: "stablelm-tuned-alpha-7b",
            # the replicate model call needs the 'version' to find it
            version: "c49dae362cbaecd2ceabb5bd34fdb68413c4ff775111fea065d259d577757beb",
            # version: "e6d469c2b11008bb0e446c3e9629232f9674581224536851272c54871f84076e",
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
          LangChain.Providers.Replicate.report_price(response)

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

            _result ->
              Process.sleep(@poll_interval)
              poll_for_prediction_result(prediction_id)
          end

        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, reason}
      end
    end

    def ask(model, chats) when is_list(chats) do
      prompt =
        chats
        |> Enum.map_join("\n", fn chat ->
          # chat.role is also here but it's not used currently
          chat.text
        end)

      ask(model, prompt)
      |> handle_responses()
    end

    # with Replicate models first create a prediction, then you poll the API call
    # until the prediction is complete, then you get the output
    def ask(model, prompt) do
      {:ok, prediction_id} = create_prediction(model, prompt)
      {:ok, output} = poll_for_prediction_result(prediction_id)
      # try to make sure output is always a simple string
      if is_list(output) do
        # join strings if they are a list:
        output |> Enum.join(" ")
      else
        output
      end
    end

    defp handle_responses(responses) when is_list(responses) do
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

    defp handle_responses(responses) when is_binary(responses) do
      responses
    end

    defp handle_responses(responses) do
      case Enum.all?(responses, &match?({:ok, _}, &1)) do
        true -> {:ok, Enum.map(responses, fn {:ok, text} -> text end)}
        false -> {:error, "One or more responses failed"}
      end
    end
  end
end
