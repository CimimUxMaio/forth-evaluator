defmodule ForthEvaluator.Parser do
  alias ForthEvaluator.Parser.Combinators

  @type word :: String.t()

  @type stack_op :: {:stack_op, atom(), [term()]}
  @type dictionary_op :: {:dictionary_op, atom(), [term()]}

  @type token :: stack_op | dictionary_op

  @spec parse_program(text_code :: String.t()) :: [token] | :error
  @doc ~S"""
  Parses a program given as plain text into a list of tokens. 

  ## Examples

      iex> ForthEvaluator.Parser.parse_program("1 2 .")
      [{:stack_op, :push, [1]}, {:stack_op, :push, [2]}, {:stack_op, :pop, []}]

      iex> ForthEvaluator.Parser.parse_program("@invalid program")
      :error

  """
  def parse_program(text_code) do
    result =
      text_code
      |> String.split()
      |> program_parser()

    case result do
      {tokens, []} -> List.flatten(tokens)
      # Error or Non empty remainder
      _ -> :error
    end
  end

  # Parser that parses a program given as a list of words into tokens.
  # If successful, returns a tuple with the matching tokens and the remaining program
  # that was not able to parse (an empty list if none).
  @spec program_parser(words :: [word]) :: {[token], [word]} | :error
  defp program_parser(words) do
    [&stack_op_parser/1, &dictionary_op_parser/1]
    |> Combinators.any()
    |> Combinators.repeat()
    |> apply([words])
  end

  # Parser that parses a program given as a list of words.
  # This parser matches only numbers and, if successful, returns a tuple 
  # with a "push" `stack_op` for the matching number and the remaining 
  # program that was not able to parse (an empty list if none).
  @spec number_parser(words :: [word]) :: {stack_op, [word]} | :error
  defp number_parser(words)

  defp number_parser([]), do: :error

  defp number_parser([head | tail]) do
    case Integer.parse(head) do
      {number, ""} -> {{:stack_op, :push, [number]}, tail}
      _ -> :error
    end
  end

  # Parser that parses a program given as a list of words.
  # This parser matches all predefined stack operations and, if successful, 
  # returns a tuple with the matching `stack_op` and the remaining 
  # program that was not able to parse (an empty list if none).
  defp predefined_stack_op_parser(words)

  defp predefined_stack_op_parser([]), do: :error

  defp predefined_stack_op_parser([head | tail]) do
    case String.upcase(head) do
      "+" -> {{:stack_op, :add, []}, tail}
      "-" -> {{:stack_op, :substract, []}, tail}
      "*" -> {{:stack_op, :multiply, []}, tail}
      "/" -> {{:stack_op, :divide, []}, tail}
      "DUP" -> {{:stack_op, :duplicate, []}, tail}
      "DROP" -> {{:stack_op, :drop, []}, tail}
      "SWAP" -> {{:stack_op, :swap, []}, tail}
      "OVER" -> {{:stack_op, :over, []}, tail}
      "." -> {{:stack_op, :pop, []}, tail}
      _ -> :error
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
      {[name, tokens], remainder} ->
        {{:dictionary_op, :store, [name, tokens]}, remainder}

      _ ->
        :error
    end
  end

  # Parser that parses a program given as a list of words.
  # This parser matches any valid word that could be evaluated, if successful, returns 
  # a tuple with the matching `dictionary_op` and the remaining 
  # program that was not able to parse (an empty list if none).
  defp evaluation_parser(words) do
    case words |> name_parser() do
      {name, remainder} -> {{:dictionary_op, :search, [name]}, remainder}
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
  defp name_parser([]), do: :error

  defp name_parser([head | tail]) do
    if valid_name?(head), do: {head, tail}, else: :error
  end

  # This function parses a program given as a list of words.
  # It matches a given string (`text`) with the first word of the program.
  # If successful, returns a tuple with the corresponding word as a 
  # string and the remaining program that was not able to parse (an empty list if none).
  defp parse_match(_text, []), do: :error

  defp parse_match(text, [head | tail]) do
    case head do
      ^text -> {text, tail}
      _ -> :error
    end
  end
end
