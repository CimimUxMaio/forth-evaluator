defmodule ForthEvaluator.Evaluator do
  alias ForthEvaluator.Stack
  alias ForthEvaluator.Dictionary
  alias ForthEvaluator.Parser

  @spec evaluate(tokens :: [Parser.token()], stack :: pid(), dictionary :: pid()) :: no_return()
  @doc """
  Evaluates a list of tokens running each encapsulated operation sequentialy
  using the provided stack and dictionary processes.
  """
  def evaluate(tokens, stack, dictionary) do
    tokens
    |> execute_tokens(stack, dictionary)
    # Compile results
    |> List.flatten()
    # Convert results to strings
    |> Enum.map(&result_to_string/1)
    # Remove empty strings
    |> Enum.filter(&(&1 != ""))
    # Produce output string
    |> Enum.join(" ")
  end

  defp execute_tokens(tokens, stack, dictionary) do
    Enum.reduce_while(tokens, [], fn token, results ->
      result = evaluate_token(stack, dictionary, token)
      results = results ++ [result]

      case result do
        {:error, _} -> {:halt, results}
        _ -> {:cont, results}
      end
    end)
  end

  # Evaluates a single token executing the correspoing operation depending of
  # the token type:
  # - Stack operation (`:stack_op`)
  # - Dictionary operation (`:dictionary_op`)
  defp evaluate_token(stack, dictionary, token) do
    case token do
      {:stack_op, operation, args} ->
        apply(Stack, operation, [stack | args])

      {:dictionary_op, operation, args} ->
        result = apply(Dictionary, operation, [dictionary | args])

        if result == :unknown do
          {:error, "Unknown word '#{List.first(args)}'"}
        else
          case operation do
            :store -> {:ok, ""}
            :search -> execute_tokens(result, stack, dictionary)
          end
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
