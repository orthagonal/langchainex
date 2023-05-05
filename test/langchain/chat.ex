defmodule LangChain.ChatTest do
  use ExUnit.Case

  def create_chat() do
    system_prompt = %LangChain.PromptTemplate{
      template: "Here is a spell name: <%= spell %>",
      input_variables: [:context],
      src: :system
    }

    user_prompt = %LangChain.PromptTemplate{
      template: "Do you know what <%= spell %> actually does?",
      input_variables: [:foo, :bar, :context],
      src: :user
    }

    ai_prompt = %LangChain.PromptTemplate{
      template:
        "I'm an AI named <%= ai_name %> and <%= spell %> is like <%= another_spell %> or <%= spell_three %> except better",
      input_variables: [:foo, :bar],
      src: :ai
    }

    generic_prompt = %LangChain.PromptTemplate{
      template: "List all the spells in the above conversation except <%= spell_three %>",
      input_variables: [:foo, :bar],
      src: :generic
    }

    %LangChain.Chat{
      prompt_messages: [
        %{prompt: system_prompt},
        %{prompt: user_prompt},
        %{prompt: ai_prompt},
        %{prompt: generic_prompt, role: "test"}
      ],
      input_variables: [:spell, :another_spell, :spell_three, :ai_name]
    }
  end

  test "Test format" do
    chat = create_chat()

    {:ok, results} =
      LangChain.Chat.format(chat, %{
        spell: "rezrov",
        another_spell: "gnusto",
        spell_three: "throck",
        ai_name: "Shodan"
      })

    messages = results |> Enum.map(fn item -> item.text end)

    assert [
             "Here is a spell name: rezrov",
             "Do you know what rezrov actually does?",
             "I'm an AI named Shodan and rezrov is like gnusto or throck except better",
             "List all the spells in the above conversation except throck"
           ] = messages
  end

  test "Test serialize" do
    {:ok, chat_serialized} =
      create_chat()
      |> LangChain.Chat.serialize()

    assert chat_serialized = %{
             input_variables: [:context, :foo, :bar],
             prompt_messages: [
               "{\"prompt\":{\"input_variables\":[\"context\"],\"partial_variables\":{},\"src\":\"user\",\"template\":\"Here's some context: {context}\"}}",
               "{\"prompt\":{\"input_variables\":[\"foo\",\"bar\",\"context\"],\"partial_variables\":{},\"src\":\"user\",\"template\":\"Hello {foo}, I'm {bar}. Thanks for the {context}\"}}",
               "{\"prompt\":{\"input_variables\":[\"foo\",\"bar\"],\"partial_variables\":{},\"src\":\"user\",\"template\":\"I'm an AI. I'm {foo}. I'm {bar}.\"}}",
               "{\"prompt\":{\"input_variables\":[\"foo\",\"bar\"],\"partial_variables\":{},\"src\":\"user\",\"template\":\"I'm a generic message. I'm {foo}. I'm {bar}.\"},\"role\":\"test\"}"
             ]
           }

    chat_deserialized =
      Enum.map(chat_serialized.prompt_messages, fn item ->
        Jason.decode!(item)
      end)

    assert [
             %{
               "prompt" => %{
                 "input_variables" => ["context"],
                 "partial_variables" => %{},
                 "src" => "user",
                 "template" => "Here's some context: {context}"
               }
             },
             %{
               "prompt" => %{
                 "input_variables" => ["foo", "bar", "context"],
                 "partial_variables" => %{},
                 "src" => "user",
                 "template" => "Hello {foo}, I'm {bar}. Thanks for the {context}"
               }
             },
             %{
               "prompt" => %{
                 "input_variables" => ["foo", "bar"],
                 "partial_variables" => %{},
                 "src" => "user",
                 "template" => "I'm an AI. I'm {foo}. I'm {bar}."
               }
             },
             %{
               "prompt" => %{
                 "input_variables" => ["foo", "bar"],
                 "partial_variables" => %{},
                 "src" => "user",
                 "template" => "I'm a generic message. I'm {foo}. I'm {bar}."
               },
               "role" => "test"
             }
           ] = chat_deserialized
  end

  # more to do here mostly dealing with validating the templates
  # to ensure all variables are present, that hasn't been implemented yet
end
