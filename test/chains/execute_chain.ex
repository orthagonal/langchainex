# defmodule ExecuteChainTest do
#   @moduledoc """
#   just a playground for self-modifying code
#   """
#   use ExUnit.Case
#   alias LangChain.LanguageModelProtocol

#   require Logger

#   @turbo %LangChain.Providers.OpenAI.LanguageModel{
#     model_name: "gpt-3.5-turbo",
#     max_tokens: 2000,
#     temperature: 0.2,
#     n: 1
#   }

#   @starcoder %LangChain.Providers.Huggingface.LanguageModel{
#     model_name: "bigcode/starcoder",
#     language_action: :generation,
#     max_new_tokens: 2000,
#     temperature: 0.2
#     # n: 1
#   }

#   def ask_for_program(program_description, previous_program \\ "", previous_error \\ "") do
#     template =
#       case previous_error do
#         "" ->
#           "
#           Request: Write elixir code that <%= program_description %>.
#           Only print the code by itself, no non-code text or surrounding quotes
#           or other marks.
#           ***[HERE]***
#         "

#         prev ->
#           "
#           Request: Write elixir code that <%= program_description %>.
#           Previous attempt: #{previous_program}
#           Error I got when running the previous attempt: #{previous_error}
#           Fix the code so it works correctly without crashing.
#           Remove any non-code text or characters or quotes.
#           Put your diagnosis of what is wrong in a comment.
#           Only print the updated code by itself, no non-code text or surrounding quotes
#           ***[HERE]***
#         "
#       end

#     request = EEx.eval_string(template, program_description: program_description)
#     IO.puts("****************passing this request:")
#     IO.inspect(request)
#     program = LanguageModelProtocol.ask(@turbo, request)

#     try do
#       IO.inspect(program)
#       res = Code.eval_string(program, turbo: @turbo, foo: [5.0, 2.3, 1.6, 7.4, 1.4])
#       IO.inspect(res)
#     rescue
#       e ->
#         error_message =
#           Map.get(e, :message, Map.get(e, :description, Map.get(e, :reason, "unknown error")))

#         # Logger.info("The evaluated code threw this error: #{e.message}")
#         ask_for_program(program_description, program, error_message)
#     end
#   end

#   @tag timeout: 120_000
#   test "execute chain can process input and execute the result in elixir" do
#     # result = ask_for_program("
#     #   assumes a list of numbers called 'foo'
#     #   was declared previously.  The code should sort the list in descending order
#     #   and remove any floats that are also whole integers.", [], [])

#     result = ask_for_program("
#       asks a language model to tell you how tall the tallest building is,
#       and give you the answer only as a number by itself.
#       Then asks another language model if that is an even number or an odd number.
#       This is how you call the model: 'LangChain.LanguageModelProtocol.ask(turbo, \"Hello?\")'
#     ")

#     # result = ask_for_program("
#     # plays three beeps on the speaker
#     # ")
#     # response =
#     #   LanguageModelProtocol.ask(
#     #     starcoder,
#     #     "Request: Write an Elixir program to print \"Hello World\".
#     #     Put the program between triple *** characters so it can be parsed out and executed with Code.eval_string/2"
#     #   )
#   end
# end
