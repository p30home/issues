defmodule Issues.CLI do
  @default_count 4

  @moduledoc """
  Hanlde the command line parsing and the dispatch to the various functions that ends up
  generating a table of the last _n_ issues in a github project
  """
  def main(argv) do
    parse_args(argv) |> process
  end

  @doc """
  `argv` can be -h or --help, chich returns :help.
  Otherwise it is a github user name, project name, and (Optionally)
  the numberof entries to format.
  Return a tuple of `{user, project, count}`, or `:help` if help was given.
  """

  def parse_args(argv) do
    OptionParser.parse(argv,
      switches: [help: :boolean],
      aliases: [h: :help]
    )
    |> elem(1)
    |> args_to_internal_representation()
  end

  def args_to_internal_representation([user, project, count]) do
    {user, project, String.to_integer(count)}
  end

  def args_to_internal_representation([user, project]) do
    {user, project, @default_count}
  end

  @spec args_to_internal_representation(any) :: :help
  def args_to_internal_representation(_) do
    :help
  end

  @spec process(any) :: none
  def process(:help) do
    IO.puts("""
    usage: issues <user> <project> [count | #{@default_count}]
    """)

    System.halt(0)
  end

  def process({user, project, count}) do
    Issues.GithubIssues.fetch(user, project)
    |> decode_response()
    |> sort_into_descending_order()
    |> last(count)
    |> Issues.TableFormatter.print_table_for_columns(["number" , "created_at" , "title"])
  end

  def last(list, count) do
    list |> Enum.take(count)
    |> Enum.reverse()
  end

  def sort_into_descending_order(list_of_issues) do
    list_of_issues
    |> Enum.sort(fn i1,i2 -> i1["created_at"] >= i2["created_at"] end)
  end

  @spec decode_response({:ok, any}) :: any
  def decode_response({:ok, body}), do: body


  def decode_response({:error, error}) do
    IO.puts "Error fetching from Github: #{error["message"]}"
    System.halt(2)
  end
end
