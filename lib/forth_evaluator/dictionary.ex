defmodule ForthEvaluator.Dictionary do
  @moduledoc """
  A dictionary stores program defined words and the tokens that they
  represent during its execution.
  """
  use Agent

  alias ForthEvaluator.{Parser, Evaluator}

  @type op_result :: {:ok, return_value :: String.t()} | {:error, error_msg :: String.t()}

  @spec start_link(initial_state :: map()) :: Agent.on_start()
  @doc """
  Starts a new Dictionary agent using the given map as its initial state.
  The default is an empty dictionary.

  ## Example

    iex> {:ok, dictionary} = start_link()
    iex> Agent.get(dictionary, &Function.identity/1)
    %{}

    iex> {:ok, dictionary} = start_link(%{"word" => []})
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

  @spec store(dict :: pid(), word :: Parser.word(), tokens :: [Parser.token()]) :: op_result
  @doc """
  Stores the given tokens under the given name into the dictionary.

    iex> {:ok, dictionary} = start_link()
    iex> Agent.get(dictionary, &Function.identity/1)
    %{}
    iex> store(dictionary, "word", [1, 2])
    iex> Agent.get(dictionary, &Function.identity/1)
    %{"word" => [1, 2]}

    iex> {:ok, dictionary} = start_link(%{"word1" => [1]})
    iex> Agent.get(dictionary, &Function.identity/1)
    %{"word1" => [1]}
    iex> store(dictionary, "word2", [2, 3])
    iex> Agent.get(dictionary, &Function.identity/1)
    %{"word1" => [1], "word2" => [2, 3]}

  """
  def store(dictionary, word, tokens) do
    Agent.update(dictionary, fn state -> Map.put(state, word, tokens) end)
    {:ok, ""}
  end

  @spec search(dict :: pid(), stack :: pid(), word :: Parser.word()) :: [op_result]
  @doc """
  Executes the tokens asociated with a given word and returns their results as a list.
  If the word is not found, returns an error.
  """
  def search(dictionary, stack, word) do
    Agent.get(dictionary, fn state ->
      case Map.get(state, word) do
        nil -> [{:error, "Unknown word '#{word}'"}]
        tokens -> Evaluator.execute_tokens(tokens, stack, dictionary)
      end
    end)
  end
end
