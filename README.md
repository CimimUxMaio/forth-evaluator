# Forth Evaluator
A Forth language implementation written in Elixir.

## What is Forth
Forth is a stack-oriented programming language and interactive integrated development environment
designed by Charles H. "Chuck" Moore and first used by other programmers in 1970.

In Forth, all syntactic elements, including variables, operators, and control flow, are defined as words.
A stack is used to pass parameters between words, leading to a Reverse Polish notation style.

Example code:
```forth
\ ------------------------------ Basic Arithmetic ------------------------------

\ Arithmetic (in fact most words requiring data) works by manipulating data on
\ the stack.
5 4 +    \ ok

\ `.` pops the top result from the stack:
.    \ 9 ok

\ More examples of arithmetic:
6 7 * .        \ 42 ok
1360 23 - .    \ 1337 ok
12 12 / .      \ 1 ok
13 2 mod .     \ 1 ok
```
- You can check more examples [here](https://learnxinyminutes.com/forth/).

## About this Project
The objective of this project is to implement an evaluator for a simple subset of Forth.

### Requirements
#### 1: Core language
The evaluator has to support the following words:
- `+`, `-`, `*`, `/` (integer arithmetic)
- `DUP`, `DROP`, `SWAP`, `OVER` (stack manipulation)

The evaluator also has to support defining new words using the customary syntax: `: word-name definition ;`.

To keep things simple, the only data type needed to support is signed integers of at least 16 bits size.

#### 2: User interface

The evaluator must also be available via a web interface served by Phoenix Liveview.

The user interface features must include:
- uploading a forth program
- requesting an evaluation
- showing the results
- a history of evaluated programs

## How it Works

The program consists of 3 main modules: the **Parser**, the **Evaluator**, and the **UI**.

### The Parser

The parser module is in charge of parsing a given program (provided as a string) into a list of
predefined tokens which could later be evaluated by the *Evaluator* module.

> [!INFO]
> You may find more detailed documentation in [docs/program_parser.md](./docs/program_parser.md).

### The Evaluator

The evaluator module is in charge of evaluating the list of tokens provided by the parser. There are 2
types of tokens:
- Tokens that represent an operation to be done with a stack.
- Tokens that represent an operation to be done to the dictionary.

This introduces the `Stack` and `Dictionary` processes. The evaluator module requires a `Stack` and a
`Dictionary` pid for it to run the evaluation logic.

The `Stack` is a process that handles the stack's state, and provides functions to operate its values
`push`, `pop`, `sum` and many more.

The `Dictionary` is a process that handles user defined words and the tokens each represents.
It functions as a hash map, where its keys are words and its values are lists of lexical tokens.

The evaluator uses this processes to execute each operation in the program.
- Executing the stack operations needed.
- Storing new user defined words.
- Interpreting user defined words.

### The Interface
The user interface is a web page served by a web server written using the Phoenix framework.

This site displays a text area, where you can write your forth code, and a button, that will trigger
the code's evaluation. Evaluation results will be printed in a side pannel.

Additionaly, the interface shows a list of previously evaluated programs, which can be loaded and
re-run.

#### The Backend
When the user requests the evaluation of a forth program, the correspoding endpoints starts two new child
processes.
1. First, the program is parsed into tokens using the `Parser` module.
2. Then, a new `Stack` and `Dictionary` processes are started and passed into the **evaluator** function
together with the parsed tokens.
3. The `Evaluator` module will produce a string with the output of the program.
4. The *stack* and *dictionary* processes are stopped.
5. The output is returned.

## Quick Start

- Launch the database
```
make db
```
- Set up the database
```
make setup_db
```
- Run the application with
```
make
```
or
```
make run
```

## Other Commands
- To compile the project use:
```
make build
```
- To run tests use:
```
make test
```
- To clean the project use:
```
make clean
```

## Dependencies
- Elixir 1.18.3 (compiled with Erlang/OTP 27)
- Phoenix 1.7.21
