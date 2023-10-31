import Config

config :open_ai_client, OpenAiClient, openai_api_key: System.get_env("OPENAI_API_KEY")
