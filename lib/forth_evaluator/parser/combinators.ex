defmodule ForthEvaluator.Parser.Combinators do
  @moduledoc """
  This module defines multiple functions that allow to combine
  or modify the given parsers.
  """

  @type parser :: ([input :: term()] -> {term(), [term()]} | :error)

  @spec any([parser]) :: parser
  @doc """
  Returns a new parser that matches when any of the given parsers
  match and fails when all fail.
  """
  def any(parsers) do
    fn words ->
      parsers
      |> Enum.map(& &1.(words))
      |> Enum.find(:error, &(&1 != :error))
    end
  end

  @spec repeat(parser) :: parser
  @doc """
  Returns a new parser that matches as many times as posible with a given parser.
  This parser returns a tuple with the list of elements that it was able to match
  and the remaining input.
  This parser can not fail, if the given parser matches 0 times the new parser will
  parse successfuly returning an empty list as match.
  """
  def repeat(parser), do: &repeat_until_error(parser, &1)

  @spec repeat_once(parser) :: parser
  @doc """
  Returns a new parser that matches as many times as posible with a given parser.
  This parser returns a tuple with the list of elements that it was able to match
  and the remaining input.
  This parser differs from `repeat` in that it fails if the given parser does not
  match at least once with the given input.
  """
  def repeat_once(parser) do
    fn words ->
      case repeat(parser).(words) do
        {[], _} -> :error
        result -> result
      end
    end
  end

  @doc """
  Returns a new parser that combines all the given parsers in sequence.
  Parsing a given input first with the first parser, then with the second, etc.
  """
  @spec sequence([parser]) :: parser
  def sequence(parsers) do
    fn words ->
      sequenced =
        parsers
        |> Enum.reduce_while({[], words}, fn parser, {matches, remainder} ->
          case parser.(remainder) do
            {[], remainder} ->
              {:cont, {matches, remainder}}

            {match, remainder} ->
              {:cont, {matches ++ [match], remainder}}

            :error ->
              {:halt, {matches, remainder}}
          end
        end)

      case sequenced do
        {[], _} -> :error
        result -> result
      end
    end
  end

  defp repeat_until_error(parser, words, previous \\ []) do
    case parser.(words) do
      :error ->
        {previous, words}

      {match, remainder} ->
        repeat_until_error(parser, remainder, previous ++ [match])
    end
  end

  @spec consume(parser) :: parser
  @doc """
  Returns a new parser that modifies a given parser by removing (consuming) its
  match. This means that if the input parser matches a given input the new parser will
  also be successful but will return an empty list as match.
  """
  def consume(parser) do
    fn words ->
      result = parser.(words)

      case result do
        :error -> :error
        {_, remainder} -> {[], remainder}
      end
    end
  end
end
