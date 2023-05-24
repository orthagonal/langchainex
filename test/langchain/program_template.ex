defmodule LangChain.ProgramTemplateTest do
  use ExUnit.Case

  test "Test format with full variables" do
    program = %LangChain.ProgramTemplate{
      template: "IO.puts \"<%= message %>\"",
      input_variables: [],
      partial_variables: %{message: "Hello, World!"}
    }
    assert {:ok, "IO.puts \"Hello, World!\""} == LangChain.ProgramTemplate.format(program, %{})
  end

  test "Test format with some variables not yet filled out" do
    program = %LangChain.ProgramTemplate{
      template: "IO.puts \"<%= message %>\"",
      input_variables: [:message],
      partial_variables: %{}
    }

    assert {:ok, "IO.puts \"Hello, World!\""} == LangChain.ProgramTemplate.format(program, %{message: "Hello, World!"})
  end

  test "Test partial" do
    program = %LangChain.ProgramTemplate{
      template: "IO.puts \"<%= message %>\"",
      input_variables: [:message],
      partial_variables: %{}
    }

    {:ok, partial_program} = LangChain.ProgramTemplate.partial(program, %{message: "Hello, World!"})
    assert [] == partial_program.input_variables
    assert %{message: "Hello, World!"} == partial_program.partial_variables
  end

  test "Test execute with full variables" do
    program = %LangChain.ProgramTemplate{
      template: "IO.puts \"<%= message %>\"",
      input_variables: [],
      partial_variables: %{message: "Hello, World!"},
      language: :elixir
    }

    {:ok, formatted_program} = LangChain.ProgramTemplate.format(program, %{})
    program = %{program | template: formatted_program}

    assert {:ok, :ok} == LangChain.ProgramTemplate.execute(program)
  end


end
