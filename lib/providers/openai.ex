defmodule LangChain.Embedding.OpenAIProvider do
  @moduledoc """
  An OpenAI implementation of the LangChain.EmbeddingProtocol.
  Use this for embedding your docs for openai models by specifying the
  model_name in your LLM.
  """

  defstruct model_name: "text-ada-001"

  defimpl LangChain.EmbeddingProtocol do
    def embed_documents(provider, documents) do
      opts = []

      with {:ok, results} <-
             ExOpenAI.Embeddings.create_embedding(documents, provider.model_name, opts) do
        case results do
          %ExOpenAI.Components.CreateEmbeddingResponse{data: data} ->
            embeddings = Enum.map(data, fn %{embedding: embedding} -> embedding end)
            {:ok, embeddings}

          _ ->
            {:error, "unexpected response from OpenAI API"}
        end
      else
        error ->
          {:error, error}
      end
    end

    def embed_query(provider, query) do
      embed_documents(provider, [query])
    end
  end
end

defmodule LangChain.Providers.OpenAI do
  @moduledoc """
  A module for interacting with OpenAI's main language models
  """
  defstruct model_name: "text-ada-001",
            max_tokens: 25,
            temperature: 0.5,
            n: 1

  defimpl LangChain.LanguageModelProtocol, for: LangChain.Providers.OpenAI do
    alias ExOpenAI.Components.CreateCompletionResponse

    def call(model, prompt) when is_tuple(prompt) do
      call(model, elem(prompt, 1))
    end

    def call(model, prompt) do
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

    defp extract_text(%CreateCompletionResponse{choices: [%{text: text} | _]}) do
      {:ok, text}
    end

    def chat(model, msgs) do
      converted = chats_to_openai(msgs)

      case ExOpenAI.Chat.create_chat_completion(converted, model.model_name, n: model.n) do
        {:ok, openai_response} ->
          response =
            openai_response.choices
            |> openai_to_chats()

          {:ok, response}

        {:error, error} ->
          {:error, error}
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

    defp openai_to_chats(choices) do
      choices
      |> Enum.map(fn choice -> %{text: choice.message.content, role: choice.message.role} end)
    end
  end
end
