defmodule ForthEvaluator.Parser.Combinators do
  @moduledoc """
  This module defines multiple functions that allow to combine
  or modify the given parsers.
  """

  @type parser :: ([words :: String.t()] ->
                     {:ok, {match :: term(), remainder :: [term()]}}
                     | {:error, message :: String.t()})

  @spec any([parser]) :: parser
  @doc """
  Returns a new parser that matches when any of the given parsers
  match and fails when all fail.
  """
  def any(parsers) when parsers != [] do
    fn words ->
      Enum.find(parsers, List.last(parsers), fn parser ->
        case parser.(words) do
          {:ok, _} -> true
          _ -> false
        end
      end).(words)
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
  def repeat(parser) do
    fn words ->
      {result, _} = repeat_until_error(parser, words)
      result
    end
  end

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
      {result, error_message} = repeat_until_error(parser, words)

      case result do
        {:ok, {[], _}} -> {:error, error_message}
        _ -> result
      end
    end
  end

  @doc """
  Returns a new parser that combines all the given parsers in sequence until all
  parsers have been matched or as soon as the first parsing error is returned.
  Parsing a given input first with the first parser, then with the second, etc.
  This parser also returns error if it doesn't find any matches.
  """
  @spec sequence([parser]) :: parser
  def sequence(parsers) do
    fn words ->
      parsers
      |> Enum.reduce_while({:ok, {[], words}}, fn parser, {_, {matches, remainder}} ->
        case parser.(remainder) do
          {:ok, {[], remainder}} ->
            {:cont, {:ok, {matches, remainder}}}

          {:ok, {match, remainder}} ->
            {:cont, {:ok, {matches ++ [match], remainder}}}

          {:error, message} ->
            {:halt, {:error, message}}
        end
      end)
    end
  end

  defp repeat_until_error(parser, words, previous \\ []) do
    case parser.(words) do
      {:ok, {match, remainder}} ->
        repeat_until_error(parser, remainder, previous ++ [match])

      {:error, error_message} ->
        {{:ok, {previous, words}}, error_message}
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
      case parser.(words) do
        {:ok, {_, remainder}} -> {:ok, {[], remainder}}
        error -> error
      end
    end
  end
end
