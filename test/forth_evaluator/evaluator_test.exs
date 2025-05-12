defmodule ForthEvaluator.EvaluatorTest do
  use ExUnit.Case, async: true

  alias ForthEvaluator.{Parser, Evaluator, Stack, Dictionary}

  setup do
    {:ok, stack} = Stack.start_link()
    {:ok, dictionary} = Dictionary.start_link()
    [stack: stack, dictionary: dictionary]
  end

  def run_program(program, context) do
    program
    |> Parser.parse_program()
    |> Evaluator.evaluate(context[:stack], context[:dictionary])
  end

  test "valid program with predefined operations", context do
    assert run_program("1 2 + 3 * .", context) == "9"
    assert run_program("1 1 - . 2 4 / .", context) == "0 2.0"
    assert run_program("2 DUP * DUP . 8 OVER . * .", context) == "4 4 32"
  end

  test "valid program with word definitions", context do
    assert run_program(": square DUP * ; 1 3 square . .", context) == "9 1"
    assert run_program(": double 2 * ; 4 double . 5 double .", context) == "8 10"
    assert run_program(": half 2 SWAP / ; 8 half . 7 half .", context) == "4.0 3.5"
  end

  test "program stops at runtime errors", context do
    assert run_program("1 2 3 . . . .", context) == "3 2 1 RuntimeError: The stack is empty."
    assert run_program("0 2 /", context) == "RuntimeError: Division by zero."
  end
end
