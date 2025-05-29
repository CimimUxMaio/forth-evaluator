defmodule ForthEvaluator.Evaluator do
  alias ForthEvaluator.Stack
  alias ForthEvaluator.Dictionary
  alias ForthEvaluator.Parser

  @spec evaluate(tokens :: [Parser.token()], stack :: pid(), dictionary :: pid()) :: String.t()
  @doc """
  Evaluates a list of tokens running each encapsulated operation sequentialy
  using the provided stack and dictionary processes and returns the program's
  output as a string.
  """
  def evaluate(tokens, stack, dictionary) do
    tokens
    |> execute_tokens(stack, dictionary)
    # Convert results to strings
    |> Enum.map(&result_to_string/1)
    # Remove empty strings
    |> Enum.filter(&(&1 != ""))
    # Produce output string
    |> Enum.join(" ")
  end

  def execute_tokens(tokens, stack, dictionary) do
    Enum.reduce_while(tokens, [], fn token, results ->
      result = [evaluate_token(stack, dictionary, token)] |> List.flatten()
      results = results ++ Enum.take_while(result, &result_is_ok?/1)

      case Enum.find(result, &result_is_error?/1) do
        nil -> {:cont, results}
        error -> {:halt, results ++ [error]}
      end
    end)
  end

  # Evaluates a single token executing the corresponding operation depending of
  # its type:
  # - Stack operation (`:stack_op`)
  # - Dictionary operation (`:dictionary_op`)
  defp evaluate_token(stack, dictionary, token)

  defp evaluate_token(stack, _dictionary, {:stack_op, operation, args}) do
    apply(Stack, operation, [stack | args])
  end

  defp evaluate_token(_stack, dictionary, {:dictionary_op, :store, args}) do
    apply(Dictionary, :store, [dictionary | args])
  end

  defp evaluate_token(stack, dictionary, {:dictionary_op, :search, args}) do
    apply(Dictionary, :search, [dictionary, stack | args])
  end

  defp result_is_error?({:error, _}), do: true
  defp result_is_error?(_), do: false

  defp result_is_ok?(result), do: not result_is_error?(result)

  defp result_to_string({:error, message}), do: "RuntimeError: #{message}"
  defp result_to_string({:ok, return_value}), do: return_value
end
