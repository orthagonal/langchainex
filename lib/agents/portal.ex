defmodule DimensionalPortal do
  @moduledoc """
    The DimensionalPortal is the 'portal between the two knowledge domains', there is a boundary between the two domains
    so we need a way to get around it.
  
    The __Program Knowledge Domain__ consists of traditional program metadata.  Things the host programming language has direct access to, like how long a string is,
    what fields are in a struct, what value is bound to a variable, what fields a function takes, etc.
  
    The __AI Knowledge Domain__ consists of semantic data encoded in a distributed fashion across synaptic weights of a neural network. It is
    not directly accessible to the host programming language, but can be accessed through the Portal.
  
    Note that the same data exists in both domains, but all we can see in the program knowledge domain is things like "foo is a binary string with 587 characters" while
    in the AI knowledge domain it only knows 'this string is a poem about a cat',  The AI isn't good at knowing the string is called 'foo' or how long it is. The program
    doesn't know what a cat is.
  
    There are a feww paths to get around this:
  
    PKD -> AIKD:
       - prompts
       - source code
       - machine state
       - program output
  
    AIKD -> PKD:
      - parsers
      - instructions to be executed in the VM
  """
end
