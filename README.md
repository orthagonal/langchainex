# LangchainEx   

- [LangchainEx](#langchainex)
    - [Overview](#overview)
  - [Installation](#installation)
  - [tl;dr GenServers](#tldr-genservers)
    - [Scraper](#scraper)
  - [LangChain Components](#langchain-components)
    - [](#)
  - [Providers](#providers)
    - [Current Language Model Providers as of May 11th 2023:](#current-language-model-providers-as-of-may-11th-2023)
    - [Current Vector DB Providers as of May 11th 2023:](#current-vector-db-providers-as-of-may-11th-2023)
    - [In Progress:](#in-progress)


### Overview

Loosely inspired by [LangChainJs](https://github.com/hwchase17/langchainjs)
This library seeks to enable core LangChain functionality but using
Elixir and OTP idioms. It provides low-level structures
you can use to build your own language chain applications
as well as high-level GenServers for accomplishing common 
natural-language processing tasks very quickly. 

Under current development with new backend providers and features added every few days.


## Installation

```elixir
def deps do
  [
    {:langchainex, "~> 0.1.0"}
  ]
end
```


## tl;dr GenServers 

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

## LangChain Components 

 LangChainEx chains are composed in a hierarchical manner, starting at 
 the most fundamental component and going up it is:

- PromptTemplate
- ChainLink
- Chain
  
 PromptTemplates are just text templates. ChainLinks wrap a PromptTemplate , which are composed of PromptTemplates. 

Components you can use to construct your own language chains
### 




## Providers

### Current Language Model Providers as of May 11th 2023:
 - OpenAI
 - Replicate API 
 - HuggingFace API
 - Bumblebee 

### Current Vector DB Providers as of May 11th 2023:
 - Pinecone Vector Storage

### In Progress:
 - pg-vector (Postgres Vector Storage)
 - weaviate (Weaviate Vector Storage)

See config.ex for list of currently supported providers


