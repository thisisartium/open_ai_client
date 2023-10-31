defmodule OpenAiClientTest do
  @moduledoc false

  use ExUnit.Case, async: true

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  defp endpoint_url(bypass) do
    "http://localhost:#{bypass.port}"
  end

  describe "post/2" do
    test "makes a post request to /foo with JSON request and response bodies", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/foo", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert body == Jason.encode!(%{foo: "foo"})

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(201, Jason.encode!(%{bar: "bar"}))
      end)

      {:ok, response} =
        OpenAiClient.post("/foo", json: %{foo: "foo"}, base_url: endpoint_url(bypass))

      assert response.status == 201
      assert response.body == %{"bar" => "bar"}
    end

    test "adds the openai api key as a bearer token in the authorization header", %{
      bypass: bypass
    } do
      api_key = Application.get_env(:open_ai_client, OpenAiClient)[:openai_api_key]

      Bypass.expect_once(bypass, "POST", "/foo", fn conn ->
        assert {"authorization", "Bearer #{api_key}"} in conn.req_headers

        Plug.Conn.resp(conn, 201, "")
      end)

      {:ok, _response} =
        OpenAiClient.post("/foo", base_url: endpoint_url(bypass))
    end

    test "adds the openai_organization_id as a request header when it is a string", %{
      bypass: bypass
    } do
      organization_id = "test_organization_id"

      Bypass.expect_once(bypass, "POST", "/foo", fn conn ->
        assert {"openai-organization", organization_id} in conn.req_headers

        Plug.Conn.resp(conn, 201, "")
      end)

      {:ok, _response} =
        OpenAiClient.post("/foo",
          base_url: endpoint_url(bypass),
          openai_organization: organization_id
        )
    end

    test "does not include the OpenAI-Organization header when the organization_id is nil", %{
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/foo", fn conn ->
        refute Enum.any?(conn.req_headers, fn {key, _value} -> key == "openai-organization" end)

        Plug.Conn.resp(conn, 201, "")
      end)

      {:ok, _response} = OpenAiClient.post("/foo", base_url: endpoint_url(bypass))
    end

    test "retries the request on a 408, 429, 500, 502, 503, or 504 http status response", %{
      bypass: bypass
    } do
      retry_statuses = [408, 429, 500, 502, 503, 504]
      {:ok, _pid} = Agent.start_link(fn -> 0 end, name: :retry_counter)

      Enum.each(retry_statuses, fn status ->
        Bypass.expect(bypass, "POST", "/foo", fn conn ->
          Agent.update(:retry_counter, &(&1 + 1))
          Plug.Conn.resp(conn, status, "")
        end)

        assert {:ok, %{status: ^status}} =
                 OpenAiClient.post("/foo",
                   base_url: endpoint_url(bypass),
                   retry_delay: 0,
                   retry_log_level: false
                 )

        assert Agent.get_and_update(:retry_counter, fn value -> {value, 0} end) == 4
      end)
    end
  end

  describe "get/2" do
    test "makes a get request to /foo with JSON response body", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/foo", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{bar: "bar"}))
      end)

      {:ok, response} =
        OpenAiClient.get("/foo", base_url: endpoint_url(bypass))

      assert response.status == 200
      assert response.body == %{"bar" => "bar"}
    end

    test "adds the openai api key as a bearer token in the authorization header", %{
      bypass: bypass
    } do
      api_key = Application.get_env(:open_ai_client, OpenAiClient)[:openai_api_key]

      Bypass.expect_once(bypass, "GET", "/foo", fn conn ->
        assert {"authorization", "Bearer #{api_key}"} in conn.req_headers

        Plug.Conn.resp(conn, 200, "")
      end)

      {:ok, _response} =
        OpenAiClient.get("/foo", base_url: endpoint_url(bypass))
    end

    test "adds the openai_organization_id as a request header when it is a string", %{
      bypass: bypass
    } do
      organization_id = "test_organization_id"

      Bypass.expect_once(bypass, "GET", "/foo", fn conn ->
        assert {"openai-organization", organization_id} in conn.req_headers

        Plug.Conn.resp(conn, 200, "")
      end)

      {:ok, _response} =
        OpenAiClient.get("/foo",
          base_url: endpoint_url(bypass),
          openai_organization: organization_id
        )
    end

    test "does not include the OpenAI-Organization header when the organization_id is nil", %{
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "GET", "/foo", fn conn ->
        refute Enum.any?(conn.req_headers, fn {key, _value} -> key == "openai-organization" end)

        Plug.Conn.resp(conn, 200, "")
      end)

      {:ok, _response} = OpenAiClient.get("/foo", base_url: endpoint_url(bypass))
    end

    test "retries the request on a 408, 429, 500, 502, 503, or 504 http status response", %{
      bypass: bypass
    } do
      retry_statuses = [408, 429, 500, 502, 503, 504]
      {:ok, _pid} = Agent.start_link(fn -> 0 end, name: :retry_counter)

      Enum.each(retry_statuses, fn status ->
        Bypass.expect(bypass, "GET", "/foo", fn conn ->
          Agent.update(:retry_counter, &(&1 + 1))
          Plug.Conn.resp(conn, status, "")
        end)

        assert {:ok, %{status: ^status}} =
                 OpenAiClient.get("/foo",
                   base_url: endpoint_url(bypass),
                   retry_delay: 0,
                   retry_log_level: false
                 )

        assert Agent.get_and_update(:retry_counter, fn value -> {value, 0} end) == 4
      end)
    end
  end
end
