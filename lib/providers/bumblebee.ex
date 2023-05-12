# any bumblebee-specific code should go in this file

defmodule LangChain.Providers.Bumblebee do
  @moduledoc """
    A module for interacting with Bumblebee models, unlike
    the other providers Bumblebee runs models on your
    local hardware, see https://hexdocs.pm/bumblebee/Bumblebee.html
  
    When you load a model with Bumblebee it will download that model from
    the Huggingface API and cache it locally, so the first time you run
    a model it will take a while to download, but after that it will be
    much faster
  """

  defstruct model_name: "gpt2",
            max_new_tokens: 25,
            temperature: 0.5,
            top_k: nil,
            top_p: nil

  # make sure you turn on BB in config.exs, it's an optional dependency
  @bumblebee_enabled Application.compile_env(:langchainex, :bumblebee_enabled)

  if @bumblebee_enabled do
    defimpl LangChain.LanguageModelProtocol, for: LangChain.Providers.Bumblebee do
      # get the Bumblebee config from config.exs

      # you can config bumblebee models from the mix.exs file
      defp get_config_from_mix(model) do
        {
          :ok,
          mix_config
        } = Application.fetch_env(:langchainex, :bumblebee)

        mix_config
      end

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

        IO.inspect(prompt)
        result = Nx.Serving.run(serving, "this is some stuff")
        IO.puts("result should be rtn from Nx.Serving.run")
        IO.inspect(result)
        result
      end

      # '{"inputs": {"past_user_inputs": ["Which movie is the best ?"],
      # "generated_responses": ["It is Die Hard for sure."], "text":"Can you explain why ?"}}' \
      def chat(model, chats) when is_list(chats) do
      end

      def prepare_input(msgs) do
        {past_user_inputs, generated_responses} =
          Enum.reduce(msgs, {[], []}, fn msg, {user_inputs, responses} ->
            role = Map.get(msg, :role, "user")

            case role do
              "user" -> {[msg.text | user_inputs], responses}
              _ -> {user_inputs, [msg.text | responses]}
            end
          end)

        last_text = List.last(msgs).text

        %{
          "inputs" => %{
            "past_user_inputs" => Enum.reverse(past_user_inputs),
            "generated_responses" => Enum.reverse(generated_responses),
            "text" => last_text
          }
        }
        |> Jason.encode!()
      end
    end
  end
end
