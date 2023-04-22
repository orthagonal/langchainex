
defmodule LangChain.Chain do
  @derive Jason.Encoder
  defstruct [
    links: []  # List of ChainLinks, processed in order
  ]

  def new(chain_links) do
    %LangChain.Chain{
      links: chain_links
    }
  end

  def call(lang_chain, previous_values) do
    # Use Enum.reduce to process the ChainLinks and accumulate the output in previous_values
    Enum.reduce(lang_chain.links, previous_values, fn chain_link, acc ->
      updated_chain_link = LangChain.ChainLink.call(chain_link, acc)
      # Merge the output of the current ChainLink with the accumulated previous values
      Map.merge(acc, updated_chain_link.output)
    end)
  end
end
