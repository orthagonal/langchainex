defmodule LangChain.Providers.Replicate do
  @moduledoc """
    A module for interacting with Replicate's API
    Replicate is a host for ML models that take in any data
    and return any data, it can be used for LLM, image generation, image parsing, sound, etc
  """

  def chat(model, chats) when is_list(chats) do
    # Implement your Replicate API chat call here
  end

  def call(model, prompt) do
    # Implement your Replicate API call here
  end
end
