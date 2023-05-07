defmodule LangChain.Providers.OpenAI do
  @moduledoc """
  A module for interacting with OpenAI's API
  """

  @doc """
  a simple call to respond to a simple text input prompt
  """
  def call(model, prompt) when is_tuple(prompt) do
    call(model, prompt |> elem(1))
  end

  def call(model, prompt) do
    {:ok, response} =
      ExOpenAI.Completions.create_completion(
        model.model_name,
        prompt: prompt,
        temperature: model.temperature,
        max_tokens: model.max_tokens
      )

    extract_text(response)
  end

  defp extract_text(%ExOpenAI.Components.CreateCompletionResponse{choices: [%{text: text} | _]}) do
    {:ok, text}
  end

  @doc """
  a call to respond to an entire chat session containing multiple PromptTemplates
  """
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
  def chats_to_openai(chats) do
    Enum.map(chats, fn chat ->
      case chat do
        %{text: text, role: role} ->
          %{content: text, role: role}

        %{role: role, content: content} ->
          %{content: content, role: role}

        _ ->
          %{}
      end
    end)
  end

  # openai response will be in the form
  # choices: [
  #   %{
  #     finish_reason: "stop",
  #     index: 0,
  #     message: %{
  #       content: "The product of 7 and 5 is 35. The square root of 35 rounded to 2-digit precision is approximately 5.92.",
  #       role: "assistant"
  #     }
  #   }, ......
  def openai_to_chats(choices) do
    choices
    |> Enum.map(fn choice -> %{text: choice.message.content, role: choice.message.role} end)
  end

  @doc """
  embed a list of documents
  """
  def embed_documents(model, documents) do
    opts = []

    with {:ok, results} <- ExOpenAI.Embeddings.create_embedding(documents, model.model_name, opts) do
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
end
