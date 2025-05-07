defmodule ForthEvaluator.ParserTest do
  use ExUnit.Case, async: true
  doctest ForthEvaluator.Parser

  test "Can parse stack operations" do
    result = ForthEvaluator.Parser.parse_program("1 + - * / DUP DROP SWAP OVER .")

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

    result = ForthEvaluator.Parser.parse_program("-1 0 1")

    assert result == [
             {:stack_op, :push, [-1]},
             {:stack_op, :push, [0]},
             {:stack_op, :push, [1]}
           ]
  end

  test "Can parse definitions references (evaluations)" do
    result = ForthEvaluator.Parser.parse_program("word1 word2")

    assert result == [
             {:evaluation_op, "word1"},
             {:evaluation_op, "word2"}
           ]
  end

  test "Can parse definitions" do
    result = ForthEvaluator.Parser.parse_program(": example 1 DUP * ;")

    assert result == [
             {:definition_op, "example",
              [{:stack_op, :push, [1]}, {:stack_op, :duplicate, []}, {:stack_op, :multiply, []}]}
           ]

    result = ForthEvaluator.Parser.parse_program(": name 300 ;")

    assert result == [
             {:definition_op, "name", [{:stack_op, :push, [300]}]}
           ]
  end

  test "Definitions can not be empty" do
    assert :error == ForthEvaluator.Parser.parse_program(": name ;")
  end

  test "Can parse multiline programs" do
    result = ForthEvaluator.Parser.parse_program(": square DUP * ;\n3 square .")

    assert result == [
             {:definition_op, "square",
              [{:stack_op, :duplicate, []}, {:stack_op, :multiply, []}]},
             {:stack_op, :push, [3]},
             {:evaluation_op, "square"},
             {:stack_op, :pop, []}
           ]
  end
end
