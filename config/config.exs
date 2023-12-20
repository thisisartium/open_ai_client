import Config

config :open_ai_client, :circuit_breaker,
  name: OpenAiClient.CircuitBreaker,
  module: OpenAiClient,
  functions: [request: 3],
  reset_timeout: 10_000,
  max_failures: 3

case config_env() do
  :prod ->
    nil

  :dev ->
    config :mix_test_interactive, clear: true

  :test ->
    nil
end
