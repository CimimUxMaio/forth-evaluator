defmodule ForthEvaluator.Dictionary do
  alias ForthEvaluator.Parser

  @moduledoc """
  A dictionary stores program defined words and the tokens that they
  represent during its execution.
  """
  use Agent

  @spec start_link(initial_state :: map()) :: Agent.on_start()
  @doc """
  Starts a new Dictionary agent using the given map as its initial state.
  The default is an empty dictionary.

  ## Example

    iex> {:ok, dictionary} = ForthEvaluator.Dictionary.start_link()
    iex> Agent.get(dictionary, &Function.identity/1)
    %{}

    iex> {:ok, dictionary} = ForthEvaluator.Dictionary.start_link(%{"word" => []})
    iex> Agent.get(dictionary, &Function.identity/1)
    %{"word" => []}

  """
  def start_link(initial_state \\ %{}) do
    Agent.start_link(fn -> initial_state end)
  end

  @spec stop(dictionary :: pid()) :: no_return()
  @doc """
  Stops the Dictionary process normally.
  """
  def stop(dictionary) do
    Agent.stop(dictionary)
  end

  @spec store(dict :: pid(), word :: Parser.word(), tokens :: [Parser.token()]) :: no_return()
  @doc """
  Stores the given tokens under the given name into the dictionary.

    iex> {:ok, dictionary} = ForthEvaluator.Dictionary.start_link()
    iex> Agent.get(dictionary, &Function.identity/1)
    %{}
    iex> ForthEvaluator.Dictionary.store(dictionary, "word", [1, 2])
    iex> Agent.get(dictionary, &Function.identity/1)
    %{"word" => [1, 2]}

    iex> {:ok, dictionary} = ForthEvaluator.Dictionary.start_link(%{"word1" => [1]})
    iex> Agent.get(dictionary, &Function.identity/1)
    %{"word1" => [1]}
    iex> ForthEvaluator.Dictionary.store(dictionary, "word2", [2, 3])
    iex> Agent.get(dictionary, &Function.identity/1)
    %{"word1" => [1], "word2" => [2, 3]}

  """
  def store(dictionary, word, tokens) do
    Agent.update(dictionary, fn state -> Map.put(state, word, tokens) end)
  end

  @spec search(dict :: pid(), word :: Parser.word()) :: [Parser.token()] | :unknown
  @doc """
  Retrieves the tokens stored under the given word.
  If the word is not in the dictionary, returns the `:unknown` atom.

    iex> {:ok, dictionary} = ForthEvaluator.Dictionary.start_link()
    iex> ForthEvaluator.Dictionary.store(dictionary, "word", [1, 2])
    iex> ForthEvaluator.Dictionary.search(dictionary, "word")
    [1, 2]

    iex> {:ok, dictionary} = ForthEvaluator.Dictionary.start_link(%{"word1" => [1]})
    iex> ForthEvaluator.Dictionary.store(dictionary, "word2", [2, 3])
    iex> ForthEvaluator.Dictionary.search(dictionary, "word2")
    [2, 3]

    iex> {:ok, dictionary} = ForthEvaluator.Dictionary.start_link()
    iex> ForthEvaluator.Dictionary.search(dictionary, "unknown_word")
    :unknown

  """
  def search(dictionary, word) do
    Agent.get(dictionary, fn state -> Map.get(state, word, :unknown) end)
  end
end
