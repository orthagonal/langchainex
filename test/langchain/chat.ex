defmodule LangChain.ChatTest do
  use ExUnit.Case

  def create_chat() do
    system_prompt = %LangChain.PromptTemplate{
      template: "Here is a spell name: <%= spell %>",
      inputVariables: [:context],
      src: :system
    }

    user_prompt = %LangChain.PromptTemplate{
      template: "Do you know what <%= spell %> actually does?",
      inputVariables: [:foo, :bar, :context],
      src: :user
    }

    ai_prompt = %LangChain.PromptTemplate{
      template:
        "I'm an AI named <%= aiName %> and <%= spell %> is like <%= anotherSpell %> or <%= spellThree %> except better",
      inputVariables: [:foo, :bar],
      src: :ai
    }

    generic_prompt = %LangChain.PromptTemplate{
      template: "List all the spells in the above conversation except <%= spellThree %>",
      inputVariables: [:foo, :bar],
      src: :generic
    }

    %LangChain.Chat{
      promptMessages: [
        %{prompt: system_prompt},
        %{prompt: user_prompt},
        %{prompt: ai_prompt},
        %{prompt: generic_prompt, role: "test"}
      ],
      inputVariables: [:spell, :anotherSpell, :spellThree, :aiName]
    }
  end

  test "Test format" do
    chat = create_chat()

    {:ok, results} =
      LangChain.Chat.format(chat, %{
        spell: "rezrov",
        anotherSpell: "gnusto",
        spellThree: "throck",
        aiName: "Shodan"
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
    {:ok, chatSerialized} =
      create_chat()
      |> LangChain.Chat.serialize()

    assert chatSerialized = %{
             inputVariables: [:context, :foo, :bar],
             promptMessages: [
               "{\"prompt\":{\"inputVariables\":[\"context\"],\"partialVariables\":{},\"src\":\"user\",\"template\":\"Here's some context: {context}\"}}",
               "{\"prompt\":{\"inputVariables\":[\"foo\",\"bar\",\"context\"],\"partialVariables\":{},\"src\":\"user\",\"template\":\"Hello {foo}, I'm {bar}. Thanks for the {context}\"}}",
               "{\"prompt\":{\"inputVariables\":[\"foo\",\"bar\"],\"partialVariables\":{},\"src\":\"user\",\"template\":\"I'm an AI. I'm {foo}. I'm {bar}.\"}}",
               "{\"prompt\":{\"inputVariables\":[\"foo\",\"bar\"],\"partialVariables\":{},\"src\":\"user\",\"template\":\"I'm a generic message. I'm {foo}. I'm {bar}.\"},\"role\":\"test\"}"
             ]
           }

    chatDeserialized =
      Enum.map(chatSerialized.promptMessages, fn item ->
        Jason.decode!(item)
      end)

    assert [
             %{
               "prompt" => %{
                 "inputVariables" => ["context"],
                 "partialVariables" => %{},
                 "src" => "user",
                 "template" => "Here's some context: {context}"
               }
             },
             %{
               "prompt" => %{
                 "inputVariables" => ["foo", "bar", "context"],
                 "partialVariables" => %{},
                 "src" => "user",
                 "template" => "Hello {foo}, I'm {bar}. Thanks for the {context}"
               }
             },
             %{
               "prompt" => %{
                 "inputVariables" => ["foo", "bar"],
                 "partialVariables" => %{},
                 "src" => "user",
                 "template" => "I'm an AI. I'm {foo}. I'm {bar}."
               }
             },
             %{
               "prompt" => %{
                 "inputVariables" => ["foo", "bar"],
                 "partialVariables" => %{},
                 "src" => "user",
                 "template" => "I'm a generic message. I'm {foo}. I'm {bar}."
               },
               "role" => "test"
             }
           ] = chatDeserialized
  end

  # more to do here mostly dealing with validating the templates
  # to ensure all variables are present, that hasn't been implemented yet
end
