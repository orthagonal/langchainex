# LangchainEx   


## Overview

Loosely inspired by [LangChain](https://python.langchain.com/en/latest/index.html#),
LangChainEx is a core AI and LLM library for Elixir/OTP projects.  It wraps
all of the gory details of the major hosted services (including [bumblebee!](https://hexdocs.pm/bumblebee/Bumblebee.html)) in an easy-to-use common interface. With LangChainEx you can skip the boring 'API' part of your project and get right to the cool 'AI' part! 

The BEAM excels at running lots of processes that are mostly 'waiting around' on network and GPU calls, this makes it an excellent environment for building complex multi-agent systems that can actually be used in a production environment. 

Use this library if you need:

- a quick boost to jump right in to programming with AI models in Elixir
- to build a properly-managed multi-agent system without having to sully yourself with Python interpreters
- to avoid vendor lock-in, with LangChainEx you can switch from OpenAI to Huggingface to Bumblebee with a single line of code   
- to combine local and remote-hosted neural networks in one OTP Application.  You can mix a proprietary in-house model that runs on your local hardware and a hosted model that runs on a remote datacenter using the same interface. .   
- to use existing langchain applications to accomplish common natural-language processing tasks very quickly. 


## Installation

```elixir
def deps do
  [
    {:langchainex, "~> 0.2.2"}
  ]
end
```

## Example

```elixir
  # Language Model (text input) examples
  goose = %LangChain.Providers.GooseAi.LanguageModel{
    model_name: "gpt-neo-20b"
  }
  goose_answer = LangChain.LanguageModelProtocol.ask(goose, "What is your favorite programming language?")
  IO.puts "Goose says: #{goose_answer}"
  # Goose says: My favorite  programming language is Elixir with a side-order of Rust.

  openai = %LangChain.Providers.OpenAI.LanguageModel{
    model_name: "gpt-3.5-turbo"
  }
  openai_answer = LangChain.LanguageModelProtocol.ask(openai, "What is your favorite programming language?")
  IO.puts "OpenAI says: #{openai_answer}"
  # OpenAI says: I don't know for sure, but I don't trust languages that can't operate more than one thread at a time.

  cohere = LangChain.Providers.Cohere.LanguageModel{
    model_name: "command"
  }
  response = LangChain.LanguageModelProtocol.ask(@cohere_model, "Why is Elixir a good language for AI applications?")
  IO.puts "Cohere says: #{response}"


  # Audio Model (audio input) examples
  @swedish_listener %LangChain.Providers.Huggingface.AudioModel{
    model_name: "marinone94/whisper-medium-swedish"
  }
  audio_data = File.read!("my_transcript.wav")
  response = AudioModelProtocol.speak(model, audio_data)
  IO.puts "Swedish Listener heard: #{response}"
  #  Swedish Listener heard: Det bästa programmeringsspråket är uppenbarligen Elixir.

  # Image Classification Model (image input) examples
  image_model_classify = %LangChain.Providers.Huggingface.ImageModel{
    language_action: :image_classification
  }
  image_data = File.read!("as_byatt_holding_a_gun.jpg")
  response_classify = ImageModelProtocol.describe(image_model_classify, image_data)
  IO.puts "Image Classification Model says: #{response_classify}"
  # Image Classifcation Model says: "woman, AS Byatt, gun, pistol" 
```

See the tests folder for more examples.

### Current Supported Providers

#### Text  
 - HuggingFace API
 - GooseAi
 - NLP Cloud
 - OpenAI
 - Replicate API 
 - Cohere
 - Bumblebee (runs on your local hardware with Nx and XLA!)

#### Audio
  - Huggingface

#### Image Classification
  - Huggingface

Under active development with new providers and features added every day

#### Vector Storage Providers
 - Pinecone Vector Storage



## LangChain Components 

LangChainEx also comes with a few higher-level components built on top of the core neural network
wrappers that you can use to build your own langchains. LangChainEx chains are composed in a hierarchical manner, starting at the most fundamental component and going up it is:

- PromptTemplate - EEx templates that can be filled in and passed to a language model 
- ChainLink - A wrapper around a PromptTemplate that preprocesses the input and post-processes the output
- Anchor - Alignment point in a chain where the AI tells you what it plans to do and gets your approval
- Chain - A sequence of ChainLinks that can be executed in order 


### Scraper

Scraper is a utility chain that extracts structured data
from natural language text. It has a handy "default_scraper" that
can be used out of the box to print out data in any format
your language model knows about (GPT-3 knows all the major formats I've tried)


In your Application tree:
```elixir
  {LangChain.Scraper, name: :scraper},
```

In your code: 
```elixir
    # start the Scraper genserver
    {:ok, pid} = Scraper.start_link()
    # Set up an LLM provider, we're using OpenAI here
    openai_provider = %LangChain.Providers.OpenAI.LanguageModel{
      model_name: "gpt-3.5-turbo",
      max_tokens: 25,
      temperature: 0.5,
      n: 1
    }

    # # Start the LLM GenServer with the OpenAI provider
    {:ok, llm_pid} = LangChain.LLM.start_link(provider: openai_provider)

    {:ok, scraper_pid} = LangChain.Scraper.start_link()

    description = "Hi I'm Nermal an 11th-level magic user with 30 hit points, I have a wand of healing and a cloak of protection in my inventory."

    character_schema = "{
      name: String,
      class: String,
      hit_points: Int,
      inventory: [String]
    }"

    {:ok, result } = LangChain.Scraper.scrape(scraper_pid, description, llm_pid, "default_scraper", %{ output_format: "YAML", input_schema: character_schema })

    IO.puts result.text
    " name: Nermal
      class: magic user
      hit_points: 30
      inventory:
        - wand of healing
        - cloak of protection
    "
```

### Notes

- Obviously, neural networks and language models are kind of a thing right now, the field is moving quickly and new 
paradigms and providers are popping up all the time.  If you have a favorite provider that you'd like to see supported or features that you'd like to see enabled, please open an issue and I'll do my best to add it. 

