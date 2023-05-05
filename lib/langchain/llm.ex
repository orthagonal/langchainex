defmodule LangChain.LLM do
  @moduledoc """
    A generic LLM interface for interacting with different LLM providers
  """
  # these are the defaults values for a LLM model
  defstruct provider: :openai,
            model_name: "text-ada-001",
            max_tokens: 25,
            temperature: 0.5,
            n: 1,
            # further provider-specific options can go here
            options: %{}

  # chats is the list of chat msgs in the form:
  #   %{text: "Here's some context: This is a context"},
  #   %{text: "Hello Foo, I'm Bar. Thanks for the This is a context"},
  #   %{text: "I'm an AI. I'm Foo. I'm Bar."},
  #   %{text: "I'm a generic message. I'm Foo. I'm Bar.", role: "test"}
  def chat(model, chats) when is_list(chats) do
    case model.provider do
      :openai -> LangChain.Providers.OpenAI.chat(model, chats)
      # :gpt3 -> handle_gpt3_call(model, prompt)
      _ -> "unknown provider #{model.provider}"
    end
  end

  # call is a single chat msg
  def call(model, prompt) do
    case model.provider do
      :openai -> LangChain.Providers.OpenAI.call(model, prompt)
      # :gpt3 -> handle_gpt3_call(model, prompt)
      _ -> "unknown provider #{model.provider}"
    end
  end
end
