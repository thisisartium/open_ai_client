defmodule OpenAiClient do
  @moduledoc """
  A client for the OpenAI API.

  This client supports all options provided by the `Req` library, as well as additional options:
  - :breaker - a circuit breaker module (default: `ExBreak`)
  - :openai_organization - the OpenAI organization ID
  """

  @doc """
  Sends a POST request to the OpenAI API.

  ## Examples

      iex> OpenAiClient.post("https://api.openai.com/v1/chat/completions",
      ...> [json: %{model: "gpt-3.5-turbo", messages: [%{role: "system", content: "You are a helpful assistant."}, %{role: "user", content: "Who won the world series in 2020?"}]}])
      {:ok, %{"id" => "chatcmpl-3o4Bz2rawi6wk8c4L8QR4W7eFCDj", "object" => "chat.completion", "created" => 1646183485, "model" => "gpt-3.5-turbo", "choices" => [%{"message" => %{ "role" => "assistant", "content" => "The Los Angeles Dodgers won the World Series in 2020."}, "finish_reason" => "stop", "index" => 0}]}}

  """
  @spec post(String.t(), Keyword.t()) :: {:ok, map()} | {:error, any()}
  def post(url, options) do
    send_request(:post, url, options)
  end

  @doc """
  Sends a GET request to the OpenAI API.

  ## Examples

      iex> OpenAiClient.get("https://api.openai.com/v1/models")
      {:ok, %{"models" => [%{"id" => "gpt-3.5-turbo", "object" => "model", "created" => 1646183485, "name" => "gpt-3.5-turbo"}]}}

  """
  @spec get(String.t(), Keyword.t()) :: {:ok, map()} | {:error, any()}
  def get(url, options) do
    send_request(:get, url, options)
  end

  defp send_request(method, url, options) do
    breaker = Keyword.get(options, :breaker, ExBreak)
    options = Keyword.delete(options, :breaker)

    breaker.call(&__MODULE__.__do_request__/3, [method, url, options],
      threshold: 10,
      timeout_sec: 120,
      match_return: &breaker_response/1
    )
  end

  defp breaker_response(response) do
    case response do
      %{status: status} when status in 500..599 -> true
      %{status: 429} -> true
      _ -> false
    end
  end

  def __do_request__(method, url, options) do
    options = Keyword.put(options, :method, method)

    build_request(url, options)
    |> Req.request()
  end

  defp build_request(url, options) do
    options
    |> Keyword.put(:url, url)
    |> validate_options()
    |> set_headers()
    |> remove_nil_values()
    |> Req.new()
  end

  defp validate_options(options) do
    Keyword.validate!(options, [
      :url,
      :json,
      :method,
      retry_delay: nil,
      retry_log_level: nil,
      retry: :transient,
      openai_organization: default_organization(),
      base_url: default_base_url(),
      auth: {:bearer, default_api_key()}
    ])
  end

  defp remove_nil_values(options) do
    Enum.reject(options, fn {_key, value} -> value == nil end)
  end

  defp default_base_url do
    Application.get_env(:open_ai_client, OpenAiClient)[:base_url]
  end

  defp default_api_key do
    Application.get_env(:open_ai_client, OpenAiClient)[:openai_api_key]
  end

  defp default_organization do
    Application.get_env(:open_ai_client, OpenAiClient)[:openai_organization_id]
  end

  defp set_headers(options) do
    headers =
      if options[:openai_organization],
        do: [{"openai-organization", options[:openai_organization]}],
        else: []

    options
    |> Keyword.put_new(:headers, headers)
    |> Keyword.delete(:openai_organization)
  end
end
