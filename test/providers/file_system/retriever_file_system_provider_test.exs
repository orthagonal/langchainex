defmodule LangChain.Retriever.FileSystemProviderTest do
	use ExUnit.Case
	doctest LangChain.Retriever.FileSystemProvider
	alias LangChain.Retriever.FileSystemProvider

  test "returns the contents of a single file as a string inside a list" do
    # Create a temporary file with content
    {:ok, tmp_file} = File.mktemp("file", ".txt")
    File.write!(tmp_file, "Sample content")

    # Call the function
    result = FileSystemProvider.get_relevant_documents(tmp_file)

    # Assert that the function returns the file content as a string inside a list
    assert result == ["Sample content"]

    # Clean up the temporary file
    File.rm!(tmp_file)
  end

  test "returns the contents of each file in a directory as a list of strings" do
    # Create a temporary directory with two files
    {:ok, tmp_dir} = File.mktmp()
    File.write!(Path.join(tmp_dir, "file1.txt"), "Sample content 1")
    File.write!(Path.join(tmp_dir, "file2.txt"), "Sample content 2")

    # Call the function
    result = FileSystemProvider.get_relevant_documents(tmp_dir)

    # Assert that the function returns the correct list of file contents
    assert Enum.count(result) == 2
    assert Enum.member?(result, "Sample content 1")
    assert Enum.member?(result, "Sample content 2")

    # Clean up the temporary directory
    File.rm_rf!(tmp_dir)
  end

  test "returns an error tuple for an invalid path" do
    # Use a non-existent path
    invalid_path = "/non/existent/path"

    # Call the function
    result = FileSystemProvider.get_relevant_documents(invalid_path)

    # Assert that the function returns an error tuple
    assert {:error, :invalid_path} = result
  end

end
