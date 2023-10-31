defmodule OpenAiClient do
  @moduledoc """
  A client for the OpenAI API.
  """

  @doc """
  Sends a POST request to the OpenAI API.
  """
  @spec post(String.t(), Keyword.t()) :: {:ok, map()} | {:error, any()}
  def post(url, options) do
    request(:post, url, options)
  end

  @doc """
  Sends a GET request to the OpenAI API.
  """
  @spec get(String.t(), Keyword.t()) :: {:ok, map()} | {:error, any()}
  def get(url, options) do
    request(:get, url, options)
  end

  @spec request(atom(), String.t(), Keyword.t()) :: {:ok, map()} | {:error, any()}
  defp request(method, url, options) do
    breaker = Keyword.get(options, :breaker, ExBreak)

    options = Keyword.delete(options, :breaker)

    breaker.call(&OpenAiClient.__do_request__/3, [method, url, options],
      threshold: 10,
      timeout_sec: 120,
      match_return: fn {:ok, response} -> breaker(response) end
    )
  end

  defp breaker(response) do
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

  @spec build_request(String.t(), Keyword.t()) :: map()
  defp build_request(url, options) do
    options
    |> Keyword.put(:url, url)
    |> Keyword.validate!([
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
    |> set_headers()
    |> Enum.reject(fn {_key, value} -> value == nil end)
    |> Req.new()
  end

  @spec default_base_url() :: String.t()
  defp default_base_url do
    Application.get_env(:open_ai_client, OpenAiClient)[:base_url]
  end

  @spec default_api_key() :: String.t()
  defp default_api_key do
    Application.get_env(:open_ai_client, OpenAiClient)[:openai_api_key]
  end

  @spec default_organization() :: String.t()
  defp default_organization do
    Application.get_env(:open_ai_client, OpenAiClient)[:openai_organization_id]
  end

  @spec set_headers(Keyword.t()) :: Keyword.t()
  defp set_headers(options) do
    headers =
      if options[:openai_organization] do
        [{"openai-organization", options[:openai_organization]}]
      else
        []
      end

    options
    |> Keyword.put_new(:headers, headers)
    |> Keyword.delete(:openai_organization)
  end
end
