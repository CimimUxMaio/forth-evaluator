# Forth Parser

To be able to execute a Forth program we first need to parse the program string
into structured "tokens" we can work with in our evaluator.

## What is a Token?
In our case, a token is defined as a tuple that has the following components:
- operation type: `:stack_op` or `:dictionary_op`.
- operation: atom representing the function to be applied to the corresponding actor.
    - `:stack_op` operations are applied to `Stack` actors,
    - and `:dictionary_op` operations are applied to `Dictionary` actors.
- operation arguments: list of arguments to be passed to the operation function.

## How do we Parse a Program?
This implementation takes inspiration in the [combinatory parsing](https://en.wikipedia.org/wiki/Parser_combinator) technique. Which
involves the creation of very simple parsers and combine them together using different
_parser combinator_ functions to produce more complex and capable parsers.

## What is a Parser?
In this project we define a parser as a function which takes a list of Forth words as input
and returns one of the following tuples:
- {:ok, {match, remainder}}
    - `match`: The value produced by the matching words from the input (words that met the parsers conditions).
    - `remainder`: List of remaining words from the input which the parser could not match.
        - Note: parsers always stop matching after the first non-matching word.
- {:error, error_message}
    - Parsers may fail if the don't match any of the first words in the input.
    - `error_message` is a string that describes why the parser failed.

## What is a Combinator?
A parser combinator is defined as a function which takes one or many parsers as input
and produces a new one.

They allow us to:
- Combine multiple parsers into one.
- Decorate a given parser and modify its behaviour.

### Examples
`Combinators.sequence` takes a list of parsers as an input and produces a single parser
which matches a given input only if all its given parsers match the input *sequentialy*.
- Meaning that the first parser will be used to match the input words, then, the next parser will
  be used to attempt to match the remaining words (that the previous parser couldn't match - its `remainder`),
  and so on until all the parsers have been used.

`Combinators.any` takes a list of parsers as an input and produces a single parser which matches
a given input by attempting to parse it with its given parsers.
- If the first parser succeeds, it will return the same as the first parser would.
- If the first parser fails, it will attempt to parse the input with the second parser from the list,
  and so on.
- If all the given parsers fail to match the input, this new parser will fail.

## The Program Parser

### Grammar

This implementation supports a small subset of the Forth language. Its grammar could be described in
BNF (Backus Naur Form) notation as follows:

```ebnf
<expr> ::= <operation> " " <expr>
        |  <operation>

<operation> ::= <stack_op> | <dictionary_op>

<stack_op> ::= <number> | <predefined_op>

<predefined_op> ::= "+" | "-" | "*" | "/" | "." | "DUP" | "DROP" | "SWAP" | "OVER"

<dictionary_op> ::= <definition> | <evaluation>

<definition> ::= ":" " " <name> " " <expr> " " ";"

<evaluation> ::= <name>
```

### Implementation
The program parser is composed by many different simple parsers which represent each structure
of the language's grammar.

![image](https://github.com/user-attachments/assets/fbf192e9-555c-4983-ae14-9e5d29cbb8eb)

This heriarchy of smaller parsers are combined together into one single "Program Parser" by using
parser combinator functions.

#### Stack Operation Parser Example

##### Parser.number_parser

The number parser is one of the simplest parsers. Given a list of words it matches with the first
word if it represents a numeric value and converts it to a stack `:push` operation.

For example:
```elixir
iex> Parser.number_parser(["1", "2", "+", "DUP", "."])
> {:ok, {{:stack_op, :push, [1]}, ["2", "+", "DUP", "."]}}

iex> Parser.number_parser(["DUP", "2", "3"])
> {:error, "DUP is not a number"}
```

##### Parser.predefined_stack_op_parser
This parser matches with the first word of the given list if it is one of the following _predefined_
forth words or fails otherwise:
- "+"
- "-"
- "*"
- "/"
- "DUP"
- "DROP"
- "SWAP"
- "OVER"
- "."

If matching it converts the matching word into it's corresponding stack operation.

For example:
```elixir
iex> Parser.predefined_stack_op_parser(["SWAP", ".", "1", "2"])
> {:ok, {{:stack_op, :swap, []}, [".", "1", "2"]}}

iex> Parser.predefined_stack_op_parser(["1", "2", "OVER"])
> {:error, "'1' is not a predefined word"}
```

##### Parser.stack_op_parser
Stack op parser is the result of combining the previous parsers
(`number_parser` and `predefined_stack_op_parser`) into one using the `any` combinator.
This parser, matches with any word that is either a number or a predefined operation,
and converts it to it's corresponding stack operation.

For example:
```elixir
iex> Parser.stack_op_parser(["1", "DUP", "hello", "."])
> {:ok, {:stack_op, :push, [1]}}

iex> Parser.stack_op_parser(["OVER", "3", "world", "."])
> {:ok, {:stack_op, :over, []}}

iex> Parser.stack_op_parser(["user_defined_word", "1", "2"])
> {:error, "'user_defined_word' is not a valid stack operation"}
```

## Conclusion
By using parser combinator functions we combined multiple simpler parsers into a single
`Parser.program_parser` which is able to parse a whole forth program. This final parser,
given a list of words, produces a list of operations ("tokens") which are later executed
by the `Evaluator` module.
