# any bumblebee-specific code should go in this file

defmodule LangChain.Providers.Bumblebee.LanguageModel do
  @moduledoc """
    A module for interacting with Bumblebee models, unlike
    the other providers Bumblebee runs models on your
    local hardware, see https://hexdocs.pm/bumblebee/Bumblebee.html

    When you load a model with Bumblebee it will download that model from
    the Huggingface API and cache it locally, so the first time you run
    a model it will take a while to download, but after that it will be
    much faster
  """

  defstruct provider: :bumblebee,
            model_name: "gpt2",
            max_new_tokens: 25,
            temperature: 0.5,
            top_k: nil,
            top_p: nil

  # make sure you turn on BB in config.exs, it's an optional dependency
  @bumblebee_enabled Application.compile_env(:langchainex, :bumblebee_enabled)

  if @bumblebee_enabled do
    defimpl LangChain.LanguageModelProtocol, for: LangChain.Providers.Bumblebee.LanguageModel do
      def call(config, prompt) do
        # this is where models get downloaded at compile time
        # models will be hundreds of MBs but will be cached by bumblebee
        # inspect the model.spec field for an overview of the model's architecture, vocab_size,
        # max_positions, pad_token_id, etc
        {:ok, model} = Bumblebee.load_model({:hf, config.model_name})

        # this is where tokenizer for that model gets downloaded, tokenizers use the model's encoding scheme
        # to turn text into numbers
        # inspect your tokenizer to see stats for your tokenizer, like vocab_size, end_of_word_suffix, etc
        {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, config.model_name})
        # inspect your generation_config to see info like min/max_new_tokens, min/max_length, etc
        # strategy, bos/eos token_id ( reserved numbers from the model's encoding scheme) etc
        {:ok, generation_config} = Bumblebee.load_generation_config({:hf, config.model_name})

        # start serving the model
        serving =
          Bumblebee.Text.generation(model, tokenizer, generation_config,
            defn_options: [compiler: EXLA]
          )

        Nx.Serving.run(serving, prompt)
        |> Map.get(:results, [])
        |> Enum.map_join(" ", fn result ->
          Map.get(result, :text, "")
        end)
      end

      # '{"inputs": {"past_user_inputs": ["Which movie is the best ?"],
      # "generated_responses": ["It is Die Hard for sure."], "text":"Can you explain why ?"}}' \

      # input will be like:
      #   msgs = [
      #     %{text: "Write a sentence containing the word *grue*.", role: "user"},
      #     %{text: "Include a reference to the Dead Mountaineers Hotel."}
      #   ]
      # pop the last item off this list and turn it into a string called 'message'
      # and put the tail of the list is the 'history' which is strings
      def chat(config, chats) when is_list(chats) do
        {:ok, model} = Bumblebee.load_model({:hf, config.model_name})
        {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, config.model_name})
        {:ok, generation_config} = Bumblebee.load_generation_config({:hf, config.model_name})
        serving = Bumblebee.Text.conversation(model, tokenizer, generation_config)
        message = List.last(chats).text
        prior = List.delete_at(chats, -1)

        Nx.Serving.run(serving, %{text: message, history: prior}) |> Map.take([:text, :history])
      end
    end
  end
end

defmodule LangChain.Providers.Bumblebee.Embedder do
  @moduledoc """
  When you want to use the Bumblebee API to embed documents.
  Embedding will transform documents into vectors of numbers that you can then feed into a neural network.
  The embedding provider must match the input size of the model and use the same encoding scheme.
  """

  defstruct model_name: "sentence-transformers/all-MiniLM-L6-v2"

  @bumblebee_enabled Application.compile_env(:langchainex, :bumblebee_enabled)
  if @bumblebee_enabled do
    defimpl LangChain.EmbedderProtocol do
      def embed_documents(provider, documents) do
        {:ok, model_info} =
          Bumblebee.load_model({:hf, provider.model_name}, log_params_diff: false)

        {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, provider.model_name})

        inputs = Bumblebee.apply_tokenizer(tokenizer, documents)

        embedding = Axon.predict(model_info.model, model_info.params, inputs, compiler: EXLA)

        {:ok, embedding}
      end

      def embed_query(provider, query) do
        embed_documents(provider, [query])
      end
    end
  end
end
