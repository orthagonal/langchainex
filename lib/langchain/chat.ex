# a list of PromptTemplate, constituting the chat dialogue up to that point
defmodule LangChain.Chat do
  @moduledoc """
  A Chat is a list of multiple PromptTemplates along with all their input variables

  """

  @derive Jason.Encoder
  defstruct template: "",
            input_variables: [],
            partial_variables: %{},
            prompt_messages: [],
            llm: %LangChain.LLM{
              provider: :openai,
              temperature: 0.1,
              max_tokens: 200,
              # model must support chat dialogue history
              model_name: "gpt-3.5-turbo"
            }

  @doc """
  loops over every prompt and formats it with the values supplied
  """
  def format(chat, values) do
    resultMessages =
      Enum.map(chat.prompt_messages, fn prompt_message ->
        {:ok, text} = LangChain.PromptTemplate.format(prompt_message.prompt, values)
        Map.put(prompt_message, :text, text)
      end)

    {:ok, resultMessages}
  end

  def toChatMessages do
  end

  def serialize(chat) do
    case Map.has_key?(chat, :output_parser) do
      true ->
        {:error, "Chat cannot be serialized if output_parser is set"}

      false ->
        {:ok,
         %{
           input_variables: chat.input_variables,
           prompt_messages: Enum.map(chat.prompt_messages, &Jason.encode!/1)
         }}
    end
  end

  @doc """
  add more PromptTemplates to the Chat
  """
  def add_prompt_templates(chat_prompt_template, prompt_list) do
    updated_prompt_messages = chat_prompt_template.prompt_messages ++ prompt_list
    %{chat_prompt_template | prompt_messages: updated_prompt_messages}
  end
end
