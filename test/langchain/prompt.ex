defmodule LangChain.PromptTemplateTest do
  use ExUnit.Case

  test "Test using partial when values are a map" do
    prompt = %LangChain.PromptTemplate{
      template: "<%= foo %><%= bar %>",
      inputVariables: [:foo],
      partialVariables: %{bar: "baz"}
    }

    res = LangChain.PromptTemplate.format(prompt, %{foo: "fop"})
    assert {:ok, "fopbaz"} == res
  end

  test "Test using full partial" do
    prompt = %LangChain.PromptTemplate{
      template: "<%= foo %><%= bar %>",
      inputVariables: [],
      partialVariables: %{bar: "baz", foo: "boo"}
    }

    assert {:ok, "boobaz"} == LangChain.PromptTemplate.format(prompt, %{})
  end

  test "Test partial" do
    prompt = %LangChain.PromptTemplate{
      template: "<%= foo %><%= bar %>",
      inputVariables: [:foo, :bar],
      partialVariables: %{}
    }

    assert [:foo, :bar] == prompt.inputVariables
    {:ok, partial_prompt} = LangChain.PromptTemplate.partial(prompt, %{foo: "foo"})
    # IO.inspect partial_prompt.inputVariables
    assert [:bar] == partial_prompt.inputVariables
    assert {:ok, "foobaz"} == LangChain.PromptTemplate.format(partial_prompt, %{bar: "baz"})
  end

  test "Test partial with function" do
    prompt = %LangChain.PromptTemplate{
      template: "<%= foo %><%= bar %>",
      inputVariables: [:foo, :bar],
      partialVariables: %{}
    }

    partial_prompt_fun = fn ->
      {:ok, "boo"}
    end

    {:ok, partial_prompt} = LangChain.PromptTemplate.partial(prompt, %{foo: partial_prompt_fun})
    assert [:bar] == partial_prompt.inputVariables
    assert {:ok, "boobaz"} == LangChain.PromptTemplate.format(partial_prompt, %{bar: "baz"})
  end
end
