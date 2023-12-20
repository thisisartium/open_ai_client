# OpenAiClient

OpenAiClient is a client for the OpenAI API. It supports all options provided by
the `Req` library, as well as additional options such as a circuit breaker
module (defaults to `ExBreak`) and the OpenAI organization ID.

## Installation

The package can be installed by adding `open_ai_client` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:open_ai_client, "~> 2.0"}
  ]
end
```

## Configuration

In your `config/runtime.exs` file, you need to set up the OpenAI API key and organization ID:

```elixir
import Config

config :open_ai_client, :base_url, System.get_env("OPENAI_BASE_URL") || "https://api.openai.com/v1",
config :open_ai_client, :openai_api_key, System.get_env("OPENAI_API_KEY") || raise("OPENAI_API_KEY is not set"),
config :open_ai_client, :openai_organization_id, System.get_env("OPENAI_ORGANIZATION_ID")
```

## Usage

You can send a POST request to the OpenAI API like this:

```elixir
{:ok, %Req.Response{} = response} = OpenAiClient.post(
  "/chat/completions", json: %{
    model: "gpt-3.5-turbo",
    messages: [
      %{role: "system", content: "You are a helpful assistant."},
      %{role: "user", content: "Who won the world series in 2020?"}
    ]
  }
)
```

And a GET request like this:

```elixir
{:ok, %Req.Response{} = response} = OpenAiClient.get("/models")
```

Because this is really just a simple wrapper around the `Req` library, see the
[Req library documentation](https://hexdocs.pm/req) for details on the
`Req.Response` module returned by these calls.

Find the published documentation for the latest version at:
https://hexdocs.pm/open_ai_client.