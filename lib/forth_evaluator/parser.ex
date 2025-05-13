defmodule ForthEvaluator.Parser do
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
      {:ok, {tokens, []}} -> {:ok, List.flatten(tokens)}
      # Error or Non empty remainder
      error -> error
    end
  end

  # Parser that parses a program given as a list of words into tokens.
  # If successful, returns a tuple with the matching tokens and the remaining program
  # that was not able to parse (an empty list if none).
  @spec program_parser(words :: [word]) :: {:ok, {[token], [word]}} | {:error, String.t()}
  defp program_parser(words) do
    [&stack_op_parser/1, &dictionary_op_parser/1]
    |> Combinators.any()
    |> Combinators.until_complete()
    |> apply([words])
  end

  # Parser that parses a program given as a list of words.
  # This parser matches only numbers and, if successful, returns a tuple 
  # with a "push" `stack_op` for the matching number and the remaining 
  # program that was not able to parse (an empty list if none).
  @spec number_parser(words :: [word]) :: {:ok, {stack_op, [word]}} | {:error, String.t()}
  defp number_parser(words)

  defp number_parser([]), do: {:error, "expected number but found nothing"}

  defp number_parser([head | tail]) do
    case Integer.parse(head) do
      {number, ""} -> {:ok, {{:stack_op, :push, [number]}, tail}}
      _ -> {:error, "expected number but found '#{head}'"}
    end
  end

  # Parser that parses a program given as a list of words.
  # This parser matches all predefined stack operations and, if successful, 
  # returns a tuple with the matching `stack_op` and the remaining 
  # program that was not able to parse (an empty list if none).
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

  # Parser that parses a program given as a list of words.
  # This parser matches any stack operation (numbers and predefined operations)
  # and, if successful, returns a tuple with the matching `stack_op` and the remaining 
  # program that was not able to parse (an empty list if none).
  defp stack_op_parser(words) do
    [&predefined_stack_op_parser/1, &number_parser/1]
    |> Combinators.any()
    |> apply([words])
  end

  # Parser that parses a program given as a list of words.
  # This parser matches any stack operation (numbers and predefined operations)
  # and, if successful, returns a tuple with the matching `dictionary_op` and the remaining 
  # program that was not able to parse (an empty list if none).
  defp dictionary_op_parser(words) do
    [&definition_parser/1, &evaluation_parser/1]
    |> Combinators.any()
    |> apply([words])
  end

  # Parser that parses a program given as a list of words.
  # This parser matches new word definitions and, if successful, returns 
  # a tuple with the matching `dictionary_op` and the remaining 
  # program that was not able to parse (an empty list if none).
  defp definition_parser(words) do
    colon_parser = Combinators.consume(&parse_match(":", &1))
    semicolon_parser = Combinators.consume(&parse_match(";", &1))

    case [colon_parser, &name_parser/1, &program_parser/1, semicolon_parser]
         |> Combinators.sequence()
         |> apply([words]) do
      {:ok, {[name, tokens], remainder}} ->
        {:ok, {{:dictionary_op, :store, [name, tokens]}, remainder}}

      error ->
        error
    end
  end

  # Parser that parses a program given as a list of words.
  # This parser matches any valid word that could be evaluated, if successful, returns 
  # a tuple with the matching `dictionary_op` and the remaining 
  # program that was not able to parse (an empty list if none).
  defp evaluation_parser(words) do
    case words |> name_parser() do
      {:ok, {name, remainder}} -> {:ok, {{:dictionary_op, :search, [name]}, remainder}}
      _ -> :error
    end
  end

  # Returns whether a name is a valid word.
  # Valid words may contain any alphanumeric characters and underscores,
  # but can only start either with a letter or an underscore.
  defp valid_name?(name) when is_binary(name) do
    Regex.match?(~r/^[a-zA-Z_][a-zA-Z0-9_]*$/, name)
  end

  # Parser that parses a program given as a list of words.
  # This parser matches any valid word, if successful, returns 
  # a tuple with the corresponding word as a string and the remaining 
  # program that was not able to parse (an empty list if none).
  defp name_parser([]), do: {:error, "expected name but found nothing"}

  defp name_parser([head | tail]) do
    if valid_name?(head), do: {:ok, {head, tail}}, else: {:error, "invalid name '#{head}'"}
  end

  # This function parses a program given as a list of words.
  # It matches a given string (`text`) with the first word of the program.
  # If successful, returns a tuple with the corresponding word as a 
  # string and the remaining program that was not able to parse (an empty list if none).
  defp parse_match(text, []), do: {:error, "expected '#{text}' but found nothing"}

  defp parse_match(text, [head | tail]) do
    case head do
      ^text -> {:ok, {text, tail}}
      _ -> {:error, "expected '#{text}' but found '#{head}'"}
    end
  end
end
