# LangchainEx   


## Overview

Loosely inspired by [LangChainJs](https://github.com/hwchase17/langchainjs),
this library seeks to enable core LangChain functionality using
Elixir and OTP idioms. It provides low-level structures
you can use to build your own language chain applications
as well as high-level GenServers for accomplishing common 
natural-language processing tasks very quickly. 

###  Use this library if you need
  - drivers for talking to hosted and local LLMs from Elixir 
  - component framework for building language chains and AI agents
  - predefined eagents for scraping structured data from natural language text

Under active development with new providers and features added every day


## Installation

```elixir
def deps do
  [
    {:langchainex, "~> 0.1.0"}
  ]
end
```

### Current Providers as of May 14th 2023:

#### Language Models 
 - OpenAI
 - Replicate API 
 - HuggingFace API
 - Bumblebee (run huggingface models locally)
#### Vector Storage With
 - Pinecone Vector Storage


## LangChain Components 

 LangChainEx chains are composed in a hierarchical manner, starting at 
 the most fundamental component and going up it is:

- PromptTemplate - EEx templates that can be filled in and passed to a language model 
- ChainLink - A wrapper around a PromptTemplate that handles any local transformations of the input and output
- Anchor - Alignment point in a chain where the AI tells you what it plans to do and gets your approval
- Chain - A sequence of ChainLinks that can be executed in order 


### Incoming:

 - pg-vector (Postgres Vector Storage)
 - weaviate (Weaviate Vector Storage)
 - vespa
 - qdrant
### Scraper

Scraper holds language chains that extract structured data
from natural language text. It has a handy "default_scraper" that
can be used out of the box.


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
