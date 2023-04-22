defmodule LangChain.Providers.OpenAI do
  # todo: support listing all the implementations assocaited with their provider atoms
  # eg { :huggingface, [ :gpt2, :gpt3, :gptneo ] }

  # a simple call to respond to a simple text input prompt
  # the prompt is probably {:ok, "some text"} just get the text
  def call(model, prompt) when is_tuple(prompt) do
    call(model, prompt |> elem(1))
  end

  def call(model, prompt) do
    ExOpenAI.Completions.create_completion(
      model.modelName,
      prompt: prompt,
      temperature: model.temperature,
      max_tokens: model.maxTokens
    )
  end

  # a call to respond to an entire chat session
  def chat(model, msgs) do
    converted = chats_to_openai(msgs)
    case ExOpenAI.Chat.create_chat_completion(converted, model.modelName, n: model.n) do
      {:ok, openai_Response} ->
        IO.puts "got a response"
        IO.puts "got a response"
        IO.puts "got a response"
        IO.puts "got a response"
        IO.inspect openai_Response
        response = openai_Response.choices
          |> openai_to_chats()
        {:ok, response}
      {:error, error} ->
        { :error, error }
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
end
