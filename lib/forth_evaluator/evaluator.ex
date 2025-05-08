defmodule ForthEvaluator.Evaluator do
  alias ForthEvaluator.Stack
  alias ForthEvaluator.Dictionary
  alias ForthEvaluator.Parser

  @spec evaluate(stack :: pid(), dictionary :: pid(), tokens :: [Parser.token()]) :: no_return()
  @doc """
  Evaluates a list of tokens running each encapsulated operation sequentialy
  using the provided stack and dictionary processes.
  """
  def evaluate(stack, dictionary, tokens) do
    tokens
    # Compile results
    |> Enum.reduce_while([], fn token, results ->
      result = evaluate_token(stack, dictionary, token)
      results = results ++ [result]

      case result do
        {:error, _} -> {:halt, results}
        _ -> {:cont, results}
      end
    end)
    |> List.flatten()
    # Convert results to strings
    |> Enum.map(&result_to_string/1)
    # Remove empty strings
    |> Enum.filter(&(&1 != ""))
    # Produce output string
    |> Enum.join(" ")
  end

  # Evaluates a single token executing the correspoing operation depending of
  # the token type:
  # - Stack operation (`:stack_op`)
  # - Word definition (`:definition_op`)
  # - Word evaluation (`:evaluation_op`)
  defp evaluate_token(stack, dictionary, token) do
    case token do
      {:stack_op, operation, args} ->
        apply(Stack, operation, [stack | args])

      {:definition_op, name, tokens} ->
        Dictionary.store(dictionary, name, tokens)
        {:ok, ""}

      {:evaluation_op, name} ->
        case Dictionary.search(dictionary, name) do
          :unknown -> {:error, "Found unknown word #{name}."}
          tokens -> evaluate(stack, dictionary, tokens)
        end
    end
  end

  defp result_to_string(result) do
    case result do
      {:error, error_message} -> "RuntimeError: #{error_message}"
      {:ok, return_value} -> to_string(return_value)
    end
  end
end
