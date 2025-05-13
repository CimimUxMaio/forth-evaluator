defmodule ForthEvaluator.ParserTest do
  use ExUnit.Case, async: true
  doctest ForthEvaluator.Parser

  test "Can parse stack operations" do
    {:ok, result} = ForthEvaluator.Parser.parse_program("1 + - * / DUP DROP SWAP OVER .")

    assert result == [
             {:stack_op, :push, [1]},
             {:stack_op, :add, []},
             {:stack_op, :substract, []},
             {:stack_op, :multiply, []},
             {:stack_op, :divide, []},
             {:stack_op, :duplicate, []},
             {:stack_op, :drop, []},
             {:stack_op, :swap, []},
             {:stack_op, :over, []},
             {:stack_op, :pop, []}
           ]

    {:ok, result} = ForthEvaluator.Parser.parse_program("-1 0 1")

    assert result == [
             {:stack_op, :push, [-1]},
             {:stack_op, :push, [0]},
             {:stack_op, :push, [1]}
           ]
  end

  test "Can parse definitions references (evaluations)" do
    {:ok, result} = ForthEvaluator.Parser.parse_program("word1 word2")

    assert result == [
             {:dictionary_op, :search, ["word1"]},
             {:dictionary_op, :search, ["word2"]}
           ]
  end

  test "Can parse definitions" do
    {:ok, result} = ForthEvaluator.Parser.parse_program(": example 1 DUP * ;")

    assert result == [
             {:dictionary_op, :store,
              [
                "example",
                [{:stack_op, :push, [1]}, {:stack_op, :duplicate, []}, {:stack_op, :multiply, []}]
              ]}
           ]

    {:ok, result} = ForthEvaluator.Parser.parse_program(": name 300 ;")

    assert result == [
             {:dictionary_op, :store, ["name", [{:stack_op, :push, [300]}]]}
           ]
  end

  test "Can parse definitions within definitions" do
    result = ForthEvaluator.Parser.parse_program(": by4 : by2 DUP + ; by2 by2 ;")

    assert result == [
             {:dictionary_op, :store,
              [
                "by4",
                [
                  {:dictionary_op, :store,
                   ["by2", [{:stack_op, :duplicate, []}, {:stack_op, :add, []}]]},
                  {:dictionary_op, :search, ["by2"]},
                  {:dictionary_op, :search, ["by2"]}
                ]
              ]}
           ]
  end

  test "Definitions can not be empty" do
    {status, msg} = ForthEvaluator.Parser.parse_program(": name ;")
    IO.puts(msg)
    assert status == :error
  end

  test "Can parse multiline programs" do
    {:ok, result} = ForthEvaluator.Parser.parse_program(": square DUP * ;\n3 square .")

    assert result == [
             {:dictionary_op, :store,
              ["square", [{:stack_op, :duplicate, []}, {:stack_op, :multiply, []}]]},
             {:stack_op, :push, [3]},
             {:dictionary_op, :search, ["square"]},
             {:stack_op, :pop, []}
           ]
  end
end
