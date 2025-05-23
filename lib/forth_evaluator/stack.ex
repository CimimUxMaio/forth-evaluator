defmodule ForthEvaluator.Stack do
  @moduledoc """
  A Stack stores a program's state during its execution.
  """
  use Agent

  @type op_result :: {:ok, return_value :: String.t()} | {:error, error_msg :: String.t()}

  @spec start_link(initial_state :: list()) :: Agent.on_start()
  @doc """
  Starts a new Stack agent using the given list as its initial state.
  The default is an empty stack.

  ## Example

    iex> {:ok, stack} = ForthEvaluator.Stack.start_link()
    iex> Agent.get(stack, &Function.identity/1)
    []

    iex> {:ok, stack} = ForthEvaluator.Stack.start_link([1, 2, 3])
    iex> Agent.get(stack, &Function.identity/1)
    [1, 2, 3]

  """
  def start_link(initial_state \\ []) when is_list(initial_state) do
    Agent.start_link(fn -> initial_state end)
  end

  @spec stop(stack :: pid()) :: no_return()
  @doc """
  Stops the Stack process normally.
  """
  def stop(stack) do
    Agent.stop(stack)
  end

  @spec pop(stack :: pid()) :: op_result
  @doc """
  Pops the top of the stack.
  If successful, returns the poped value as a string.
  If the stack is empty, returns an error and its description.

  ## Example

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link([1, 2])
      iex> ForthEvaluator.Stack.pop(stack)
      {:ok, "1"}
      iex> ForthEvaluator.Stack.pop(stack)
      {:ok, "2"}
      iex> ForthEvaluator.Stack.pop(stack)
      {:error, "The stack is empty."}

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link()
      iex> ForthEvaluator.Stack.pop(stack)
      {:error, "The stack is empty."}

  """
  def pop(stack) do
    Agent.get_and_update(stack, fn state ->
      case state do
        [head | tail] -> success(tail, to_string(head))
        _ -> failure(state, :single)
      end
    end)
  end

  @spec push(stack :: pid(), value :: number()) :: op_result
  @doc """
  Pushes a new element to the top of the stack and returns an 
  empty string (meaning there is no return value for this operation).

  ## Example

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link()
      iex> Agent.get(stack, &Function.identity/1)
      [] 
      iex> ForthEvaluator.Stack.push(stack, 10)
      {:ok, ""}
      iex> Agent.get(stack, &Function.identity/1)
      [10] 
      iex> ForthEvaluator.Stack.push(stack, 20)
      {:ok, ""}
      iex> Agent.get(stack, &Function.identity/1)
      [20, 10] 

  """
  def push(stack, value) do
    Agent.update(stack, fn state -> [value | state] end)
    {:ok, ""}
  end

  @spec add(stack :: pid()) :: op_result
  @doc """
  Adds the top two elements of the stack removing them from it and placing
  the result at the top.
  If successful, returns an empty string (meaning there is no return value for this operation).
  If there aren't at least 2 elements in the stack, returns an error and its description.

  ## Example

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link([2, 2])
      iex> ForthEvaluator.Stack.add(stack)
      {:ok, ""} 
      iex> Agent.get(stack, &Function.identity/1)
      [4]

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link([1])
      iex> ForthEvaluator.Stack.add(stack)
      {:error, "There are not enough elements in the stack."} 

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link()
      iex> ForthEvaluator.Stack.add(stack)
      {:error, "There are not enough elements in the stack."} 

  """
  def add(stack) do
    binary_operation(stack, fn a, b -> a + b end)
  end

  @spec substract(stack :: pid()) :: op_result
  @doc """
  Substracts the top two elements of the stack removing them from it and placing
  the result at the top.
  If successful, returns an empty string (meaning there is no return value for this operation).
  If there aren't at least 2 elements in the stack, returns an error and its description.

  ## Example

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link([3, 6])
      iex> ForthEvaluator.Stack.substract(stack)
      {:ok, ""} 
      iex> Agent.get(stack, &Function.identity/1)
      [-3]

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link([100])
      iex> ForthEvaluator.Stack.substract(stack)
      {:error, "There are not enough elements in the stack."} 

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link()
      iex> ForthEvaluator.Stack.substract(stack)
      {:error, "There are not enough elements in the stack."} 

  """
  def substract(stack) do
    binary_operation(stack, fn a, b -> a - b end)
  end

  @spec multiply(stack :: pid()) :: op_result
  @doc """
  Multiplies the top two elements of the stack removing them from it and placing
  the result at the top.
  If successful, returns an empty string (meaning there is no return value for this operation).
  If there aren't at least 2 elements in the stack, returns an error and its description.

  ## Example

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link([2, 3, 4])
      iex> ForthEvaluator.Stack.multiply(stack)
      {:ok, ""} 
      iex> Agent.get(stack, &Function.identity/1)
      [6, 4]

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link([50])
      iex> ForthEvaluator.Stack.multiply(stack)
      {:error, "There are not enough elements in the stack."} 

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link()
      iex> ForthEvaluator.Stack.multiply(stack)
      {:error, "There are not enough elements in the stack."} 

  """
  def multiply(stack) do
    binary_operation(stack, fn a, b -> a * b end)
  end

  @spec divide(stack :: pid()) :: op_result
  @doc """
  Divides the top two elements of the stack removing them from it and placing
  the result at the top.
  If successful, returns an empty string (meaning there is no return value for this operation).
  If there aren't at least 2 elements in the stack, returns an error and its description.
  If the second element is 0, returns an error and its description.

  ## Example

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link([40, 2, 1, 2, 3])
      iex> ForthEvaluator.Stack.divide(stack)
      {:ok, ""} 
      iex> Agent.get(stack, &Function.identity/1)
      [20.0, 1, 2, 3]

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link([3, 0])
      iex> ForthEvaluator.Stack.divide(stack)
      {:error, "Division by zero."}

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link([3])
      iex> ForthEvaluator.Stack.divide(stack)
      {:error, "There are not enough elements in the stack."} 

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link()
      iex> ForthEvaluator.Stack.divide(stack)
      {:error, "There are not enough elements in the stack."} 

  """
  def divide(stack) do
    elements = Agent.get(stack, &Function.identity/1)

    # Peek at the 2nd element.
    case Enum.at(elements, 1, :invalid_index) do
      :invalid_index -> failure_response(:double)
      0 -> {:error, "Division by zero."}
      _ -> binary_operation(stack, fn a, b -> a / b end)
    end
  end

  @spec duplicate(stack :: pid()) :: op_result
  @doc """
  Duplicates the top element in the stack, placing a copy of it at the top.
  If successful, returns an empty string (meaning there is no return value for this operation).
  If the stack is empty, returns an error and its description.

  ## Example

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link([99, 1, 2])
      iex> ForthEvaluator.Stack.duplicate(stack)
      {:ok, ""} 
      iex> Agent.get(stack, &Function.identity/1)
      [99, 99, 1, 2]

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link([3])
      iex> ForthEvaluator.Stack.duplicate(stack)
      {:ok, ""} 
      iex> Agent.get(stack, &Function.identity/1)
      [3, 3]

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link()
      iex> ForthEvaluator.Stack.duplicate(stack)
      {:error, "The stack is empty."} 

  """
  def duplicate(stack) do
    Agent.get_and_update(stack, fn state ->
      case state do
        [head | tail] -> success([head, head | tail])
        _ -> failure(state, :single)
      end
    end)
  end

  @spec drop(stack :: pid()) :: op_result
  @doc """
  Removes the top of the stack.
  If successful, returns an empty string (meaning there is no return value for this operation).
  If the stack is empty, returns an error and its description.

  This function is equivalent to `pop` without its return value.

  ## Example

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link([1, 2])
      iex> ForthEvaluator.Stack.drop(stack)
      {:ok, ""}
      iex> Agent.get(stack, &Function.identity/1)
      [2]

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link([4, 5, 6])
      iex> ForthEvaluator.Stack.drop(stack)
      {:ok, ""}
      iex> ForthEvaluator.Stack.drop(stack)
      {:ok, ""}
      iex> ForthEvaluator.Stack.drop(stack)
      {:ok, ""}
      iex> Agent.get(stack, &Function.identity/1)
      []

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link()
      iex> ForthEvaluator.Stack.pop(stack)
      {:error, "The stack is empty."}

  """
  def drop(stack) do
    case pop(stack) do
      {:ok, _} -> {:ok, ""}
      error -> error
    end
  end

  @spec swap(stack :: pid()) :: op_result
  @doc """
  Swaps the two top elements of the stack.
  If successful, returns an empty string (meaning there is no return value for this operation).
  If there aren't at least 2 elements in the stack, returns an error and its description.

  ## Example

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link([1, 2])
      iex> ForthEvaluator.Stack.swap(stack)
      {:ok, ""}
      iex> Agent.get(stack, &Function.identity/1)
      [2, 1]

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link([3, 4, 5, 6])
      iex> ForthEvaluator.Stack.swap(stack)
      {:ok, ""}
      iex> Agent.get(stack, &Function.identity/1)
      [4, 3, 5, 6]

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link([3])
      iex> ForthEvaluator.Stack.swap(stack)
      {:error, "There are not enough elements in the stack."}

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link()
      iex> ForthEvaluator.Stack.swap(stack)
      {:error, "There are not enough elements in the stack."}

  """
  def swap(stack) do
    Agent.get_and_update(stack, fn state ->
      case state do
        [x, y | tail] -> success([y, x | tail])
        _ -> failure(state, :double)
      end
    end)
  end

  @spec over(stack :: pid()) :: op_result
  @doc """
  Pushes a copy of the second element to the top of the stack. Essentially pushing the second 
  element over the first.
  If successful, returns an empty string (meaning there is no return value for this operation).
  If there aren't at least 2 elements in the stack, returns an error and its description.

  ## Example

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link([1, 2])
      iex> ForthEvaluator.Stack.over(stack)
      {:ok, ""}
      iex> Agent.get(stack, &Function.identity/1)
      [2, 1, 2]

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link([3, 4, 5, 6])
      iex> ForthEvaluator.Stack.over(stack)
      {:ok, ""}
      iex> Agent.get(stack, &Function.identity/1)
      [4, 3, 4, 5, 6]

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link([3])
      iex> ForthEvaluator.Stack.over(stack)
      {:error, "There are not enough elements in the stack."}

      iex> {:ok, stack} = ForthEvaluator.Stack.start_link()
      iex> ForthEvaluator.Stack.over(stack)
      {:error, "There are not enough elements in the stack."}

  """
  def over(stack) do
    Agent.get_and_update(stack, fn state ->
      case state do
        [x, y | tail] -> success([y, x, y | tail])
        _ -> failure(state, :double)
      end
    end)
  end

  defp binary_operation(stack, fun) do
    Agent.get_and_update(stack, fn state ->
      case state do
        [x, y | tail] ->
          success([fun.(x, y) | tail])

        _ ->
          failure(state, :double)
      end
    end)
  end

  defp success(state, result \\ "") do
    {{:ok, result}, state}
  end

  defp failure(state, kind) do
    {failure_response(kind), state}
  end

  defp failure_response(kind) do
    error_msg =
      case kind do
        :single -> "The stack is empty."
        :double -> "There are not enough elements in the stack."
      end

    {:error, error_msg}
  end
end
