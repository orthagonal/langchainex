# LangchainEx   

- [LangchainEx](#langchainex)
    - [Overview](#overview)
  - [Installation](#installation)
  - [GenServers](#genservers)
    - [Scraper](#scraper)


### Overview

Loosely inspired by [LangChainJs](https://github.com/hwchase17/langchainjs)
This library seeks to enable core LangChain functionality but using
Elixir and OTP idioms. It provides low-level structures
you can use to build your own language chain applications
as well as high-level GenServers for accomplishing common 
natural-language processing tasks very quickly. 

## Installation

```elixir
def deps do
  [
    {:langchainex, "~> 0.1.0"}
  ]
end
```

Be sure to set your OPENAI_API_KEY and OPENAI_ORGANIZATION_KEY in your environment variables before using.


## GenServers 

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
