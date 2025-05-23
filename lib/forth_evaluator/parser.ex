defmodule ForthEvaluator.Parser do
  @moduledoc """
  This modules defines the `program_parser` and a function that executes it
  with a given program string (`parse_program`).

  The program parser is composed by many different, smaller and simpler parsers.

  Each parser is a function that takes a list of words as input and outputs
  a match tuple of the form `{ok, {match, remainder}}`. 

  The match portion is the matching value produced by the matching words in the 
  list (from the begining) and the parser's internal logic.

  The remainder portion is the list of words from the input that the parser
  failed to match.

  In the end, given a list of words N, a parser may produce a match for the first
  M words, producing a remainder of N - M words.

  The ok portion indicates whether the parser failed or not, it can be either `:ok`
  or `:error`.

  For example, the number parser parses the first word of the list into a stack 
  push operation:

    iex> number_parser(["1", "2", "3"])
    {:ok, {{:stack_op, :push, [1]}, ["2", "3"]}} # => Remainder: ["2", "3"]

    iex> number_parser(["hello", "world"])
    {:error, "expected number but found nothing"}
  """

  alias ForthEvaluator.Parser.Combinators

  @type word :: String.t()

  @type stack_op :: {:stack_op, atom(), [term()]}
  @type dictionary_op :: {:dictionary_op, atom(), [term()]}

  @type token :: stack_op | dictionary_op

  @spec parse_program(text_code :: String.t()) :: {:ok, [token]} | {:error, msg :: String.t()}
  @doc ~S"""
  Parses a program given as plain text into a list of tokens. 

  ## Examples

      iex> ForthEvaluator.Parser.parse_program("1 2 .")
      {:ok, [{:stack_op, :push, [1]}, {:stack_op, :push, [2]}, {:stack_op, :pop, []}]}

      iex> ForthEvaluator.Parser.parse_program("@_invalid_word program")
      {:error, "invalid name '@_invalid_word'"}

  """
  def parse_program(text_code) do
    result =
      text_code
      |> String.split()
      |> program_parser()

    case result do
      {:ok, {tokens, _}} -> {:ok, List.flatten(tokens)}
      error -> error
    end
  end

  # Parser that parses a program given as a list of words into tokens.
  # If successful, returns a tuple with the matching tokens and the remaining program
  # that was not able to parse (an empty list if none).
  @spec program_parser(words :: [word]) :: {:ok, {[token], [word]}} | {:error, String.t()}
  defp program_parser(words) do
    Combinators.until_complete(&operation_parser/1) |> apply([words])
  end

  defp expresion_parser(words) do
    Combinators.repeat_once(&operation_parser/1) |> apply([words])
  end

  # Parser that parses the first word of the list of words into a stack push operation.
  # If the word is a numeric value, it succeeds. Otherwise it returns an error tuple.
  @spec number_parser(words :: [word]) :: {:ok, {stack_op, [word]}} | {:error, String.t()}
  defp number_parser(words)

  defp number_parser([]), do: {:error, "expected number but found nothing"}

  defp number_parser([head | tail]) do
    case Integer.parse(head) do
      {number, ""} -> {:ok, {{:stack_op, :push, [number]}, tail}}
      _ -> {:error, "expected number but found '#{head}'"}
    end
  end

  # Parser that parses the first word of the list of words into a stack predefined operation.
  # If the word matches a predefined command, it succeeds. Otherwise it returns an error tuple.
  defp predefined_stack_op_parser(words)

  defp predefined_stack_op_parser([]), do: {:error, "expected operation but found nothing"}

  defp predefined_stack_op_parser([head | tail]) do
    case String.upcase(head) do
      "+" -> {:ok, {{:stack_op, :add, []}, tail}}
      "-" -> {:ok, {{:stack_op, :substract, []}, tail}}
      "*" -> {:ok, {{:stack_op, :multiply, []}, tail}}
      "/" -> {:ok, {{:stack_op, :divide, []}, tail}}
      "DUP" -> {:ok, {{:stack_op, :duplicate, []}, tail}}
      "DROP" -> {:ok, {{:stack_op, :drop, []}, tail}}
      "SWAP" -> {:ok, {{:stack_op, :swap, []}, tail}}
      "OVER" -> {:ok, {{:stack_op, :over, []}, tail}}
      "." -> {:ok, {{:stack_op, :pop, []}, tail}}
      _ -> {:error, "expected operation but found '#{head}'"}
    end
  end

  # Parser that parses the first N words of the list of words into any operation.
  # If the words match either a stack operation or a dictionary operation, it succeeds. 
  # Otherwise it returns an error tuple.
  defp operation_parser(words) do
    [&stack_op_parser/1, &dictionary_op_parser/1]
    |> Combinators.any()
    |> apply([words])
  end

  # Parser that parses the first word of the list of words into any stack operation.
  # If the word matches either a numeric value or a predefined command, it succeeds. 
  # Otherwise it returns an error tuple.
  defp stack_op_parser(words) do
    [&predefined_stack_op_parser/1, &number_parser/1]
    |> Combinators.any()
    |> apply([words])
  end

  # Parser that parses the first N words of the list of words into a dictionary operation.
  # If the words match either a definition or an evaluation, it succeeds. 
  # Otherwise it returns an error tuple.
  defp dictionary_op_parser(words) do
    [&definition_parser/1, &evaluation_parser/1]
    |> Combinators.any()
    |> apply([words])
  end

  # Parser that parses the first N words of the list of words into a dictionary definition
  # operation.
  # If the words match a definition structure, it succeeds. 
  # Otherwise it returns an error tuple.
  def definition_parser(words) do
    colon_parser = Combinators.consume(&parse_match(":", &1))
    semicolon_parser = Combinators.consume(&parse_match(";", &1))

    case [colon_parser, &name_parser/1, &expresion_parser/1, semicolon_parser]
         |> Combinators.sequence()
         |> apply([words]) do
      {:ok, {[name, tokens], remainder}} ->
        {:ok, {{:dictionary_op, :store, [name, tokens]}, remainder}}

      error ->
        error
    end
  end

  # Parser that parses the first word of the list of words into a dictionary evaluation operation.
  # If the word matches with a valid name, it succeeds. 
  # Otherwise it returns an error tuple.
  defp evaluation_parser(words) do
    case words |> name_parser() do
      {:ok, {name, remainder}} -> {:ok, {{:dictionary_op, :search, [name]}, remainder}}
      error -> error
    end
  end

  # Returns whether a name is a valid word.
  # Valid words may contain any alphanumeric characters and underscores,
  # but can only start either with a letter or an underscore.
  defp valid_name?(name) when is_binary(name) do
    Regex.match?(~r/^[a-zA-Z_][a-zA-Z0-9_]*$/, name)
  end

  # Parser that parses the first word of the list of words into a name.
  # If the word matches with a valid name, it succeeds. 
  # Otherwise it returns an error tuple.
  defp name_parser([]), do: {:error, "expected name but found nothing"}

  defp name_parser([head | tail]) do
    if valid_name?(head), do: {:ok, {head, tail}}, else: {:error, "invalid name '#{head}'"}
  end

  # This function matches a given string (`text`) with the first word of a list of words.
  # If the word mathces the input, is succeeds returning a parser success tuple.
  # Otherwise, it fails, returning a parser failure tuple.
  defp parse_match(text, []), do: {:error, "expected '#{text}' but found nothing"}

  defp parse_match(text, [head | tail]) do
    case head do
      ^text -> {:ok, {text, tail}}
      _ -> {:error, "expected '#{text}' but found '#{head}'"}
    end
  end
end
