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
  # Language Model (text input) example
  goose = %LangChain.Provides.GooseAi.LanguageModel{
    model_name: "gpt-neo-20b"
  }
  goose_answer = LanguageModelProtocol.ask(goose, "What is your favorite programming language?")
  IO.puts "Goose says: #{goose_answer}"
  # Goose says: My favorite  programming language is Elixir with a side-order of Rust.

  openai = %LangChain.Provides.OpenAi.LanguageModel{
    model_name: "gpt-turbo-3.5"
  }
  openai_answer = LanguageModelProtocol.ask(openai, "What is your favorite programming language?")
  IO.puts "OpenAI says: #{openai_answer}"
  # OpenAI says: I don't know for sure, but I don't trust languages that can't operate more than one thread at a time.

  @swedish_listener %LangChain.Providers.Huggingface.AudioModel{
    model_name: "marinone94/whisper-medium-swedish"
  }
  audio_data = File.read!(@audio_file)
  response = AudioModelProtocol.speak(model, audio_data)
  IO.puts "Swedish Listener heard: #{response}"
  #  Swedish Listener heard: Det bästa programmeringsspråket är uppenbarligen Elixir.
```

See the tests folder for more examples.

### Current Supported Providers

#### Text  
 - Bumblebee (runs on your own hardware with Nx and XLA!)
 - GooseAi
 - HuggingFace API
 - NLP Cloud
 - OpenAI
 - Replicate API 

#### Audio
  - Huggingface
  - Bumblebee (under construction)
  - (more to come)

#### Image (coming soon)

Under active development with new providers and features added every day

#### Vector Storage Providers
 - Pinecone Vector Storage
 - weaviate (under construction)



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
  description = "Hi I'm Nermal an 11th-level magic user with 30 hit points, I have a wand of healing and a cloak of protection in my inventory."

  character_schema = "{
    name: String,
    class: String,
    hit_points: Int,          
    inventory: [String]
  }"

  {:ok, result } = LangChain.Scraper.scrape(:scraper, description, "default_scraper", %{ output_format: "YAML", input_schema: character_schema }) 

  IO.puts result.text 
  " name: Nermal
    class: magic user
    hit_points: 30
    inventory:
      - wand of healing
      - cloak of protection
  "
    end
```

### Notes

- Obviously, neural networks and language models are kind of a thing right now, the field is moving quickly and new 
paradigms and providers are popping up all the time.  If you have a favorite provider that you'd like to see supported or features that you'd like to see enabled, please open an issue and I'll do my best to add it. 
- This is intended to be a springboard library that helps you get up and running with AI very quickly, without having to worry about the gory details of the underlying providers.  
