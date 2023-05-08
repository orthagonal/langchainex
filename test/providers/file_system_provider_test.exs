defmodule FileSystemProviderTest do
  use ExUnit.Case
  alias LangChain.Retriever
  alias LangChain.Retriever.FileSystemProvider

  setup do
    provider = %FileSystemProvider{}
    {:ok, provider: provider}
  end

  test "get_relevant_documents/1 with file path", %{provider: provider} do
    # get the path to *this* file
    path = __ENV__.file
    result = Retriever.get_relevant_documents(provider, path)

    assert result
           |> List.first()
           |> String.starts_with?("defmodule FileSystemProviderTest do")
  end

  test "get_relevant_documents/1 with directory path", %{provider: provider} do
    # get the path to the directory containing *this* file
    path = Path.dirname(__ENV__.file)

    result = Retriever.get_relevant_documents(provider, path)

    assert result != {:error, :invalid_path}

    assert Enum.any?(result, fn content ->
             content
             |> String.starts_with?("defmodule FileSystemProviderTest do")
           end)
  end

  test "get_relevant_documents/1 with invalid path", %{provider: provider} do
    # use an invalid path
    path = "/nonexistent/path"

    result = Retriever.get_relevant_documents(provider, path)

    assert result == {:error, :invalid_path}
  end
end
