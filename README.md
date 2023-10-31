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
    {:open_ai_client, "~> 0.1.0"}
  ]
end
```

## Configuration

In your `config/runtime.exs` file, you need to set up the OpenAI API key:

```elixir
config :open_ai_client, OpenAiClient, openai_api_key: System.get_env("OPENAI_API_KEY")
```

## Usage

You can send a POST request to the OpenAI API like this:

```elixir
OpenAiClient.post("https://api.openai.com/v1/chat/completions", [json: %{model: "gpt-3.5-turbo", messages: [%{role: "system", content: "You are a helpful assistant."}, %{role: "user", content: "Who won the world series in 2020?"}]}])
```

And a GET request like this:

```elixir
OpenAiClient.get("https://api.openai.com/v1/models")
```

Documentation can be generated with
[ExDoc](https://github.com/elixir-lang/ex_doc) and published on
[HexDocs](https://hexdocs.pm). Once published, the docs can be found at
<https://hexdocs.pm/open_ai_client>.