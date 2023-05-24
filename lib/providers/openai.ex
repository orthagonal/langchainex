defmodule LangChain.Providers.OpenAI do
  @moduledoc """
  OpenAI results return a body that will contain:
   `'usage': {'prompt_tokens': 56, 'completion_tokens': 31, 'total_tokens': 87}`

   OpenAI Pricing
  Model	Prompt	Completion
  gpt-4
    8K context	$0.03 / 1K tokens	$0.06 / 1K tokens
    32K context	$0.06 / 1K tokens	$0.12 / 1K tokens

  gpt-3.5-turbo	$0.002 / 1K tokens

  instructGPT (only models you can fine tune)
  Ada $0.0004 / 1K tokens
  Babbage $0.0005 / 1K tokens
  Curie $0.0020 / 1K tokens
  Davinci $0.0200 / 1K tokens
  Fine-tuning:
  Ada	$0.0004 / 1K tokens	$0.0016 / 1K tokens
  Babbage	$0.0006 / 1K tokens	$0.0024 / 1K tokens
  Curie	$0.0030 / 1K tokens	$0.0120 / 1K tokens
  Davinci	$0.0300 / 1K tokens	$0.1200 / 1K tokens

  embeddings
  Ada	$0.0004 / 1K tokens
  """

  # need to update this to scrape from page
  @pricing_structure %{
    "gpt-4-8k" => %{
      dollars_per_token: 0.00003
    },
    "gpt-4-32k" => %{
      dollars_per_token: 0.00006
    },
    "gpt-3.5" => %{
      dollars_per_token: 0.000002
    },
    "ada" => %{
      dollars_per_token: 0.0004
    },
    "babbage" => %{
      dollars_per_token: 0.0005
    },
    "curie" => %{
      dollars_per_token: 0.0020
    },
    "davinci" => %{
      dollars_per_token: 0.0200
    },
    :fine_tuning => %{
      "ada" => %{
        dollars_per_token: 0.0004
      },
      "babbage" => %{
        dollars_per_token: 0.0006
      },
      "curie" => %{
        dollars_per_token: 0.0030
      },
      "davinci" => %{
        dollars_per_token: 0.0300
      }
    },
    :embedding => %{
      "ada" => %{
        dollars_per_token: 0.0004
      }
    }
  }

  # get most-similar entry from pricing structure
  def get_pricing_structure(model_name) do
    @pricing_structure
    |> Enum.map(fn {key, value} ->
      if is_binary(key) do
        {String.jaro_distance(model_name, key), key, value}
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.max_by(fn {score, _, _} -> score end)
    |> case do
      {score, _key, value} when score > 0.7 -> value
      _ -> 0
    end
  end

  @doc """
  Used to report the price of a response from OpenAI
  Needs to implement callbacks to a master pricing tracker
  """
  def report_price(model, response) do
    try do
      total_tokens = response.usage.total_tokens
      pricing_structure = get_pricing_structure(response.model)

      total_price =
        (pricing_structure.dollars_per_token * total_tokens)
        |> :erlang.float_to_binary(decimals: 8)

      LangChain.Agents.TheAccountant.store(%{
        provider: :openai,
        model_name: model.model_name,
        total_price: total_price
      })

      # IO.puts("OpenAI #{total_tokens} tokens cost $#{total_price}")
    rescue
      error -> error
    end
  end
end

defmodule LangChain.Embedder.OpenAIProvider do
  @moduledoc """
  An OpenAI implementation of the LangChain.EmbedderProtocol.
  Use this for embedding your docs for openai models by specifying the
  model_name in your LLM.
  """

  defstruct model_name: "text-ada-001"

  defimpl LangChain.EmbedderProtocol do
    def embed_documents(provider, documents) do
      opts = []

      with {:ok, results} <-
             ExOpenAI.Embeddings.create_embedding(documents, provider.model_name, opts) do
        case results do
          %ExOpenAI.Components.CreateEmbeddingResponse{data: data} ->
            embeddings = Enum.map(data, fn %{embedding: embedding} -> embedding end)
            {:ok, embeddings}

          {:error, error} ->
            {:error, error}
        end
      end
    end

    def embed_query(provider, query) do
      embed_documents(provider, [query])
    end
  end
end

defmodule LangChain.Providers.OpenAI.LanguageModel do
  @moduledoc """
  A module for interacting with OpenAI's main language models
  """

  defstruct provider: :openai,
            model_name: "gpt-3.5-turbo",
            max_tokens: 25,
            temperature: 0.1,
            n: 1

  defimpl LangChain.LanguageModelProtocol, for: LangChain.Providers.OpenAI.LanguageModel do
    alias ExOpenAI.Components.CreateCompletionResponse

    # these models require the prompt be presented as a 'chat'
    # or sequence of messages
    @chatmodels [
      "gpt-4",
      "gpt-4-0314",
      "gpt-4-32k",
      "gpt-4-32k-0314",
      "gpt-3.5-turbo",
      "gpt-3.5-turbo-0301"
    ]
    defp chat_model?(model_name) do
      model_name in @chatmodels
    end

    def ask(model, prompt) do
      # some models are conversational and others are single-prompt only,
      # this handles fixing it up so it works either way
      if chat_model?(model.model_name) do
        # prompt is either a string or a list of messages
        msgs =
          if is_binary(prompt) do
            [%{text: prompt, role: "user"}]
          else
            prompt
          end

        chat(model, msgs)
      else
        # prompt is either a string or a list of messages, needs to just
        # be a single string for this model
        msg =
          if is_binary(prompt) do
            prompt
          else
            prompt |> Enum.map_join("\n", & &1.text)
          end

        {:ok, response} =
          ExOpenAI.Completions.create_completion(
            model.model_name,
            prompt: msg,
            temperature: model.temperature,
            max_tokens: model.max_tokens
          )

        # extract_text is a list, call only returns the first text
        extract_text(response)
      end
    end

    defp extract_text(%CreateCompletionResponse{choices: [%{text: text} | _]}) do
      text
    end

    defp chat(model, msgs) do
      converted = chats_to_openai(msgs)

      case ExOpenAI.Chat.create_chat_completion(converted, model.model_name, n: model.n) do
        {:ok, response} ->
          LangChain.Providers.OpenAI.report_price(model, response)

          cond do
            # if it's a list just return the first 'text' field
            is_list(response) ->
              response
              |> List.first()
              |> Map.get(:text)

            # if it's a map it should have a choices.message field with the 'content' or 'text'
            is_map(response) ->
              response
              |> Map.get(:choices, %{})
              |> List.first()
              |> Map.get(:message, %{})
              |> Map.get(:content, "I could not understand the result I got back")

            true ->
              "Here is the response I got back: #{inspect(response)}"
          end

        {:error, error} ->
          "Model #{model.model_name}: I had an error processing.  This is the error message: #{inspect(error)}"
      end
    end

    # convert any list of chats to open ai format
    # [
    #   %{text: "hello", role: "user"},
    #   %{text: "hi"}
    # ] should be converted to
    # [
    #   %{content: "hello", role: "user"},
    #   %{content: "hi", role: "assistant"}
    # ]
    defp chats_to_openai(chats) do
      Enum.map(chats, fn chat ->
        case chat do
          %{role: role, text: text} ->
            %{content: text, role: role}

          %{text: text} ->
            %{content: text, role: "assistant"}

          %{content: content, role: role} ->
            %{content: content, role: role}

          _ ->
            %{}
        end
      end)
    end
  end
end
