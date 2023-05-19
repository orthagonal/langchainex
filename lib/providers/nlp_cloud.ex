# all nlp cloud-specific code should go in this file
defmodule LangChain.Providers.NlpCloud do
  @moduledoc """
  NLP Cloud Provider
  https://nlpcloud.com/
  This module is predominantly used for internal API handling

  @models %{
    "fast-gpt-j" => "A fast implementation of the GPT-J model.",
    "finetuned-gpt-neox-20b" =>
      "Fine-tuned GPT-NeoX 20B will work better than Fast GPT-J. It supports many non-English languages.",
    "dolphin" =>
      "Dolphin, an NLP Cloud in-house model, has a great accuracy at an affordable price. It supports many non-English languages.",
    "chatdolphin" =>
      "ChatDolphin, an NLP Cloud in-house model, has a great accuracy at an affordable price. It supports many non-English languages."
  }

  """

  @doc """
  Used to report the price of a response from Replicate
  """
  def report_price(token_usage) do
    try do
      # just assume it's a cpu for right now:
      # pricing_structure = @pricing_structure[:cpu]
      # %{"metrics" => %{"predict_time" => predict_time}} = response

      # total_price =
      #   (pricing_structure.dollars_per_second * predict_time)
      #   |> :erlang.float_to_binary(decimals: 8)

      LangChain.Agents.TheAccountant.store(%{
        provider: :nlp_cloud,
        token_usage: token_usage
      })

      # IO.puts("Replicate #{predict_time} seconds cost $#{total_price}")
    rescue
      error -> error
    end
  end

  def get_base(model) do
    {:ok, [token: token]} = Application.fetch_env(:langchainex, :nlp_cloud)

    url =
      case model.language_action do
        :conversation -> "https://api.nlpcloud.io/v1/gpu/#{model.model_name}/chatbot"
        :generation -> "https://api.nlpcloud.io/v1/gpu/#{model.model_name}/generation"
      end

    headers = [
      {"Authorization", "Token #{token}"},
      {"Content-Type", "application/json"}
    ]

    %{
      url: url,
      headers: headers
    }
  end

  def prepare_body(model, question) when is_binary(question) do
    case model.language_action do
      :conversation ->
        %{
          "input" => question,
          "context" => "",
          "history" => []
        }
        |> Jason.encode!()

      :generation ->
        %{
          "text" => question,
          "max_length" => model.max_length
        }
        |> Jason.encode!()
    end
  end

  def prepare_body(model, question) when is_list(question) do
    case model.language_action do
      :conversation ->
        input = List.last(question) |> Map.get(:text, "")
        # get all but last itme:
        history =
          question
          |> List.delete(-1)
          |> Enum.map(fn i ->
            if Map.get(i, :role, "assistant") == "user" do
              %{"input" => i.text}
            else
              %{"response" => i.text}
            end
          end)

        %{
          "input" => input,
          "context" => "",
          "history" => history
        }
        |> Jason.encode!()

      :generation ->
        input = question |> Enum.map_join("\n", fn i -> i.text end)

        %{
          "text" => input,
          "max_length" => model.max_length
        }
        |> Jason.encode!()
    end
  end

  def handle_response(model, body) do
    decoded_body = Jason.decode!(body)

    # price reporting is always the same:
    LangChain.Providers.NlpCloud.report_price(%{
      "nb_generated_tokens" => decoded_body["nb_generated_tokens"],
      "nb_input_tokens" => decoded_body["nb_input_tokens"]
    })

    case model.language_action do
      :conversation ->
        decoded_body["response"]

      :generation ->
        text = decoded_body["generated_text"]
        text
    end
  end
end

defmodule LangChain.Providers.NlpCloud.LanguageModel do
  @moduledoc """
  Language model implementation for NLP Cloud.
  """

  # Define the struct for the model
  defstruct provider: :nlp_cloud,
            model_name: "dolphin",
            language_action: :generation,
            max_length: 50

  # Implementation of the protocol for this model
  defimpl LangChain.LanguageModelProtocol, for: LangChain.Providers.NlpCloud.LanguageModel do
    def ask(model, question) do
      base = LangChain.Providers.NlpCloud.get_base(model)
      body = LangChain.Providers.NlpCloud.prepare_body(model, question)

      case HTTPoison.post(base.url, body, base.headers) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          LangChain.Providers.NlpCloud.handle_response(model, body)

        {:ok, %HTTPoison.Response{status_code: _status_code, body: _body}} ->
          # credo:disable-for-next-line
          # IO.inspect(body)

          "I experienced a technical malfunction trying to run #{model.model_name}. Please try again later."

        {:error, %HTTPoison.Error{reason: _reason}} ->
          # credo:disable-for-next-line
          # IO.inspect(reason)

          "I experienced a technical malfunction trying to run #{model.model_name}. Please try again later."
      end
    end
  end
end
