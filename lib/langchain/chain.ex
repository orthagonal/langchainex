defmodule LangChain.Chain do
  @moduledoc """
  A chain of ChainLinks to be processed in order, usually ending in an anchor for user confirmation.
  """

  @derive Jason.Encoder
  defstruct [
    # List of ChainLinks, processed in order
    links: []
  ]

  @doc """
  Creates a new Chain struct with the given chain_links.
  """
  def new(chain_links) do
    %LangChain.Chain{
      links: chain_links
    }
  end

  @doc """
  Processes the ChainLinks in the chain and accumulates the output.
  If the optional `anchor` parameter is set to `true`, an anchor step will be added at the end of the chain for user confirmation.
  """
  def call(lang_chain, llm_pid, previous_values, anchor \\ false) do
    # Use Enum.reduce to process the ChainLinks and accumulate the output in previous_values
    result =
      Enum.reduce(lang_chain.links, previous_values, fn chain_link, acc ->
        updated_chain_link = LangChain.ChainLink.call(chain_link, llm_pid, acc)
        # Merge the output of the current ChainLink with the accumulated previous values
        Map.merge(acc, updated_chain_link.output)
      end)

    # anchor behavior is under development still
    if anchor do
      case LangChain.Anchor.CLI.get_confirmation() do
        :yes -> result
        :no -> {:error, "User declined"}
      end
    else
      result
    end
  end

  # def call(lang_chain, previous_values, anchor \\ false) do
  #   # Use Enum.reduce to process the ChainLinks and accumulate the output in previous_values
  #   result =
  #     Enum.reduce(lang_chain.links, previous_values, fn chain_link, acc ->
  #       updated_chain_link = LangChain.ChainLink.call(chain_link, acc)
  #       # Merge the output of the current ChainLink with the accumulated previous values
  #       Map.merge(acc, updated_chain_link.output)
  #     end)

  #   if anchor do
  #     case LangChain.Anchor.confirm(:query, result) do
  #       :yes -> result
  #       :no -> {:error, "User declined"}
  #     end
  #   else
  #     result
  #   end
  # end
end
