# credo:disable-for-this-file
# bumblebee is an optional dep so we need to disable credo for this file
# any bumblebee-specific code should go in this file
# bumblebee will need to be updated to support
# keeping the model in memory when it's not in use

defmodule LangChain.Providers.Bumblebee do
  @moduledoc """
  Input Processing for the Bumblebee models
  """

  def prepare_input(:for_masked_language_modeling, chats) when is_binary(chats) do
    chats
  end

  # turns it into one big string separated by newlines
  def prepare_input(:for_masked_language_modeling, chats) when is_list(chats) do
    Enum.map_join(chats, "\n", fn x -> x.text end)
  end

  def prepare_input(:for_masked_language_modeling, chats) when is_map(chats) do
    Map.get(chats, :text, "")
  end

  # when is_binary(chats) do
  def prepare_input(:for_causal_language_modeling, chats) when is_binary(chats) do
    chats
    # prepare_input(:for_conversational_language_modeling, chats)
  end

  def prepare_input(:for_causal_language_modeling, chats) when is_list(chats) do
    Enum.map_join(chats, "\n", fn x -> x.text end)
  end

  def prepare_input(:for_conversational_language_modeling, chats) when is_binary(chats) do
    # i may change this to split chats on newlines and put them in history???
    %{text: chats, history: []}
  end

  def prepare_input(:for_conversational_language_modeling, chats) when is_list(chats) do
    message = List.last(chats).text

    prior =
      List.delete_at(chats, -1)
      |> Enum.map(fn x ->
        if x.role == "assistant" do
          {:generated, x.text}
        else
          {:user, x.text}
        end
      end)

    %{text: message, history: prior}
  end
end

defmodule LangChain.Providers.Bumblebee.LanguageModel do
  @moduledoc """
    A module for interacting with Bumblebee language models, unlike
    the other providers Bumblebee runs models on your
    local hardware, see https://hexdocs.pm/bumblebee/Bumblebee.html

    When you load a model with Bumblebee it will download that model from
    the Huggingface API and cache it locally, so the first time you run
    a model it will take a while to download, but after that it will be
    much faster
  """

  defstruct provider: :bumblebee,
            model_name: "distilgpt2",
            max_new_tokens: 25,
            temperature: 0.5,
            top_k: nil,
            top_p: nil

  # make sure you turn on BB in config.exs, it's an optional dependency
  @bumblebee_enabled Application.compile_env(:langchainex, :bumblebee_enabled)

  if @bumblebee_enabled do
    defimpl LangChain.LanguageModelProtocol, for: LangChain.Providers.Bumblebee.LanguageModel do
      def ask(config, prompt) do
        try do
          # this is where models get downloaded at compile time
          # models will be hundreds of MBs but will be cached by bumblebee
          # inspect the model.spec field for an overview of the model's architecture, vocab_size,
          # max_positions, pad_token_id, etc
          {:ok, model} = Bumblebee.load_model({:hf, config.model_name})
          # this is where tokenizer for that model gets downloaded, tokenizers use the model's encoding scheme
          # to turn text into numbers
          # inspect your tokenizer to see stats for your tokenizer, like vocab_size, end_of_word_suffix, etc
          IO.puts "getting the tokenizer"
          IO.inspect config
          {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, config.model_name})
          IO.puts "tokenzier"
          IO.inspect tokenizer
          execute_model(model.spec.architecture, config, prompt, model, tokenizer)
        rescue
          _e ->
            IO.inspect _e
            "Model Bumblebee #{config.model_name}: I had a system malfunction trying to process that request."
        end
      end

      # HANDLE DIFFERENT MODEL TYPES WITH 'ask'
      def execute_model(
            :for_masked_language_modeling,
            _model_config,
            prompt,
            bumblebee_model,
            tokenizer
          ) do
        # use Bumblebee.Text.fill_mask if architecture is :for_masked_language_modeling
        serving =
          Bumblebee.Text.fill_mask(bumblebee_model, tokenizer, defn_options: [compiler: EXLA])

        input = LangChain.Providers.Bumblebee.prepare_input(:for_masked_language_modeling, prompt)

        # verify the input contains the mask token
        if String.contains?(input, tokenizer.special_tokens.mask) do
          response = Nx.Serving.run(serving, input)

          # Extract the token of the first prediction
          token_of_first_prediction =
            response
            |> Map.get(:predictions)
            |> List.first()
            |> Map.get(:token)

          # currently I just return the token, since it's assumed you can fill it in yourself
          # but in future we might switch to just return the whole statement like so:
          # String.replace(prompt, tokenizer.special_tokens.mask, token_of_first_prediction)
          token_of_first_prediction
        else
          "I was passed the string #{input} but it doesn't contain the mask token #{tokenizer.special_tokens.mask}"
        end
      end

      # handles either :for_causal_language_modeling or :for_conversational_language_modeling
      def execute_model(architecture, model_config, prompt, bumblebee_model, tokenizer) do
        # Default to Bumblebee.Text.generation
        # inspect your generation_config to see info like min/max_new_tokens, min/max_length, etc
        # strategy, bos/eos token_id ( reserved numbers from the model's encoding scheme) etc
        {:ok, generation_config} =
          Bumblebee.load_generation_config({:hf, model_config.model_name})

        serving =
          Bumblebee.Text.generation(bumblebee_model, tokenizer, generation_config,
            defn_options: [compiler: EXLA]
          )

        input = LangChain.Providers.Bumblebee.prepare_input(architecture, prompt)
        IO.inspect(input)
        result = Nx.Serving.run(serving, input)
        # %{text: message, history: prior})
        IO.inspect(result)

        result
        |> Map.get(:results, [])
        |> Enum.map_join(" ", fn result ->
          Map.get(result, :text, "")
        end)
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
