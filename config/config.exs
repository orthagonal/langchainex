import Config

# Bumblebee is an awesome library that automates downloading and running Huggingface
# models on your local CPU or GPU. You can use these models interchangeably
# with all of the hosted API models in this project. You will want to also install
# and compile EXLA to execute these models on any reasonable time frame
config :langchainex, :bumblebee_enabled, true

# Weaviate API (they offer cloud services or you can host your own instance)
config :langchainex, :weaviate,
  # see https://weaviate.io/developers/wcs/guides/authentication for Weaviate Cloud Service keys
  api_key: System.get_env("WEAVIATE_API_KEY"),
  index_name: System.get_env("WEAVIATE_INDEX_NAME", "langchainex"),
  # url for your client, see https://console.weaviate.cloud/dashboard
  client: System.get_env("WEAVIATE_CLIENT", "https://cloud.semi.technology"),
  text_key: System.get_env("WEAVIATE_TEXT_KEY", "text")

# Huggingface Inference API https://huggingface.co/docs/api-inference/index
config :langchainex, :huggingface, api_key: System.get_env("HUGGINGFACE_API_KEY")

# Replicate AI https://replicate.ai/docs
config :langchainex, :replicate,
  api_key: System.get_env("REPLICATE_API_KEY"),
  # Replicate has a polling-based API, you can configure your polling interval
  poll_interval: 1000

# you can config your providers and API keys here
config :ex_openai,
  # find it at https://platform.openai.com/account/api-keys
  api_key: System.get_env("OPENAI_API_KEY"),
  # find it at https://platform.openai.com/account/api-keys
  organization_key: System.get_env("OPENAI_ORGANIZATION_KEY"),
  # optional, passed to [HTTPoison.Request](https://hexdocs.pm/httpoison/HTTPoison.Request.html) options
  http_options: [recv_timeout: 50_000]

# you can have multiple pinecone db configs, this one is named :pinecone but you can add more
config :langchainex, :pinecone,
  # log in to Pinecone dashboard and go to API Keys to find this
  api_key: System.get_env("PINECONE_API_KEY"),
  # Pinecone dashboard -> Indexes to find this
  # eg myindex-abcd123.svc.us-east-1-aws.pinecone.io  -----------> index_name is "myindex"
  index_name: System.get_env("PINECONE_INDEX"),
  # Pinecone dashboard -> Indexes, under the Index Name column the project id will be in the index the part between the index name and ".svc" in the full index name
  # eg myindex-abcd123.svc.us-east-1-aws.pinecone.io  -----------> project_id is "abcd123"
  project_id: System.get_env("PINECONE_PROJECT_ID"),
  # Pinecone dashboard -> Indexes, look under 'environment' to find this, it's also in the full index url
  # eg myindex-abcd123.svc.us-east-1-aws.pinecone.io ------------> environment is "us-east-1-aws"
  environment: System.get_env("PINECONE_ENVIRONMENT")

config :logger, :console, format: "[$level] $message\n"
