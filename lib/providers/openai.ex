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
            temperature: 0.5,
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

    def call(model, prompt) when is_tuple(prompt) do
      call(model, elem(prompt, 1))
    end

    def call(model, prompt) do
      # some models are conversational and others are single-prompt only,
      # this handles fixing it up so it works either way
      if chat_model?(model.model_name) do
        msgs = [%{text: prompt, role: "user"}]
        chat(model, msgs)
      else
        {:ok, response} =
          ExOpenAI.Completions.create_completion(
            model.model_name,
            prompt: prompt,
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

    def chat(model, msgs) do
      converted = chats_to_openai(msgs)

      case ExOpenAI.Chat.create_chat_completion(converted, model.model_name, n: model.n) do
        {:ok, response} ->
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
          "Model #{model.model_name}: I had an error processing #{msgs}.  This is the error message: #{inspect(error)}"
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
