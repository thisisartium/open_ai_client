defmodule OpenAiClient do
  @moduledoc """
  A client for the OpenAI API.
  """

  @doc """
  Sends a POST request to the OpenAI API.
  """
  @spec post(String.t(), Keyword.t()) :: {:ok, map()} | {:error, any()}
  def post(url, options) do
    build_request(url, options)
    |> Req.post()
  end

  @doc """
  Sends a GET request to the OpenAI API.
  """
  @spec get(String.t(), Keyword.t()) :: {:ok, map()} | {:error, any()}
  def get(url, options) do
    build_request(url, options)
    |> Req.get()
  end

  @spec build_request(String.t(), Keyword.t()) :: map()
  defp build_request(url, options) do
    options
    |> Keyword.put(:url, url)
    |> Keyword.validate!([
      :url,
      :json,
      openai_organization: default_organization(),
      base_url: default_base_url(),
      auth: {:bearer, default_api_key()}
    ])
    |> set_headers()
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
