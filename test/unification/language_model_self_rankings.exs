defmodule LangChain.LanguageModelUnifiedCallTest do
  use ExUnit.Case, async: true
  alias LangChain.LanguageModelProtocol
  require Logger

  @implementations_and_models [
    # {%LangChain.Providers.Huggingface.LanguageModel{
    #    model_name: "openai-gpt"
    #  }, %{}}
    # {%LangChain.Providers.Bumblebee.LanguageModel{}, %{}},
    # {%LangChain.Providers.Replicate.LanguageModel{}, %{}}
    # {%LangChain.Providers.OpenAI.LanguageModel{}, %{}},
    # {%LangChain.Providers.NlpCloud.LanguageModel{}, %{}},
    # {%LangChain.Providers.GooseAi.LanguageModel{}, %{}}
    # {%AnotherImplementation{}, %{model_name: "model_name"}},
  ]

  # Test input
  @query "What is the capital of Paris?"

  # Test to rank models
  @tag timeout: :infinity
  test "rank_models/0 ranks models based on their responses to a query" do
    models =
      @implementations_and_models
      |> Enum.map(fn {impl, params} ->
        Map.merge(impl, params)
      end)

    # Generate responses for the query from all models
    responses =
      Enum.map(models, fn model ->
        response = LanguageModelProtocol.ask(model, @query)
        {model, response}
      end)

    # Construct ranking query based on the responses
    results =
      responses
      |> Enum.map_join("\n", fn {model, response} ->
        "#{model.provider}'s model #{model.model_name} responded with: #{response}"
      end)

    ranking_query = results <> "Rank these models in terms of how well they did."

    # |> (Enum.join("\n") <> "\nRank these models in order of how well they did.")

    # Ask each model to rank the responses
    rankings =
      Enum.map(models, fn model ->
        ranking = LanguageModelProtocol.ask(model, ranking_query)
        {model, ranking}
      end)

    # Print the rankings
    Enum.each(rankings, fn {model, ranking} ->
      IO.puts("*******************************************************************************")

      IO.puts(
        "\n#{model.provider}'s model #{model.model_name} ranked the models as follows:\n#{ranking}"
      )
    end)
  end
end
