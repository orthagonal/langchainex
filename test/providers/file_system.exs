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
    query = %{path: path}
    result = Retriever.get_relevant_documents(provider, query)

    assert result
           |> List.first()
           |> String.starts_with?("defmodule FileSystemProviderTest do")
  end

  test "get_relevant_documents/1 with directory path", %{provider: provider} do
    # get the path to the directory containing *this* file
    path = Path.dirname(__ENV__.file)
    query = %{path: path}
    result = Retriever.get_relevant_documents(provider, query)

    assert result != {:error, :invalid_path}

    assert Enum.any?(result, fn content ->
             content
             |> String.starts_with?("defmodule FileSystemProviderTest do")
           end)
  end

  test "get_relevant_documents/1 with invalid path", %{provider: provider} do
    # use an invalid path
    path = "/nonexistent/path"
    query = %{path: path}
    result = Retriever.get_relevant_documents(provider, query)

    assert result == {:error, :invalid_path}
  end

  test "get_relevant_documents/1 with recursive option", %{provider: provider} do
    # get the path to the parent directory of the directory containing *this* file
    # ie recursively read in the entire /test directory and all subdirectories
    path = Path.dirname(__ENV__.file) |> Path.dirname()
    query = %{path: path, recursive: true}
    result = Retriever.get_relevant_documents(provider, query)

    assert result != {:error, :invalid_path}
    # make sure it's got a lot of entries in it, the exact number will change and isn't important
    assert Enum.count(result) > 8
    assert Enum.any?(result, &String.starts_with?(&1, "defmodule FileSystemProviderTest do"))
  end

  test "get_relevant_documents/1 with file_extensions option", %{provider: provider} do
    # get the path to the directory containing *this* file
    path = Path.dirname(__ENV__.file)
    query = %{path: path, file_extensions: [".exs"]}
    result = Retriever.get_relevant_documents(provider, query)

    assert result != {:error, :invalid_path}
    assert Enum.any?(result, &String.starts_with?(&1, "defmodule FileSystemProviderTest do"))

    query_ex = %{path: path, file_extensions: [".ex"]}
    result_ex = Retriever.get_relevant_documents(provider, query_ex)

    assert result_ex != {:error, :invalid_path}

    assert Enum.any?(result_ex, &String.starts_with?(&1, "defmodule FileSystemProviderTest do")) ==
             false
  end

  test "get_relevant_documents/1 with ignore_extensions option", %{provider: provider} do
    # get the path to the directory containing *this* file
    path = Path.dirname(__ENV__.file)
    query = %{path: path, ignore_extensions: [".exs"]}
    result = Retriever.get_relevant_documents(provider, query)

    assert result != {:error, :invalid_path}

    assert Enum.any?(result, &String.starts_with?(&1, "defmodule FileSystemProviderTest do")) ==
             false
  end
end
