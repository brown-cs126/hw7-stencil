# Homework 7: Parsing

In this homework, you'll implement a top-down predictive parser for an
alternative syntax for our language. This syntax is called ML (Brown), because
it bears a vague resemblance to ML-family languages like OCaml. We'll usually
refer to it as MLB. Here's an example of an MLB program:

```
function add_up(a, b, c) =
  a + b = c

let x = 
  if 
    add_up(read_num(), read_num(), read_num())
  then 1
  else 2 
in
print(x)
```

Unlike the previous assignments, you won't be modifying either the interpreter
or the compiler. We've provided an AST-based version of the HW6 compiler and
interpreter, and functions to produce the AST from S-expressions. You'll write a
parser that produces the *same* AST but that instead reads in MLB-format source
code.

## MLB syntax

Here's a grammar (like the ones we discussed in class) for MLB:

```
<program> ::= <defns> <expr>

<defns> ::=
  | epsilon
  | <defn> <defns>

<defn> ::=
  | FUNCTION ID LPAREN <params> EQ <expr>

<params> ::=
  | RPAREN
  | ID <rest-params>

<rest-params> ::=
  | RPAREN
  | COMMA ID <rest-params>

<expr> ::=
  | IF <expr> THEN <expr> ELSE <expr>
  | LET ID EQ <expr> IN <expr>
  | <seq>

<seq> ::=
  | <infix1> <rest-seq>

<rest-seq> ::=
  | epsilon
  | SEMICOLON <infix1> <rest-seq>

<infix1> ::=
  | <infix2> <infix1'>

<infix1'> ::=
  | epsilon
  | EQ <infix1>
  | LT <infix1>

<infix2> ::=
  | <term> <infix2'>

<infix2'> ::=
  | epsilon
  | PLUS <infix2>
  | MINUS <infix2>

<term> ::=
  | ID
  | ID LPAREN <args>
  | NUM
  | LPAREN <expr> RPAREN

<args> ::=
  | RPAREN
  | <expr> <rest-args>

<rest-args> ::=
  | RPAREN
  | COMMA <expr> <rest-args>
```

This grammar does not have any left-recursion or left-ambiguity (the only
 exception is in `<term>`, where you can easily handle the two `ID` cases with
 careful pattern-matching). We recommend writing a recursive-descent parser like
 the ones we developed in class:

- Write one function per non-terminal (with the exception of primed cases--for
  instance, you can handle `infix'` inside the function for `infix`)
- Return a value (usually, but not always, an expression) and a list of tokens
  from each function
- Decide which production rule to use by examining the front of the token list

## The code

You'll write your parser in `mlb_syntax/parser.ml`. There is a tokenizer
implemented in `mlb_syntax/tokenizer.ml`; it shouldn't be necessary to change
it, but you can if you want to. 

The AST you'll produce is defined in `ast/ast.ml`; it's quite similar to the AST
we defined in class. A few hints for mapping the MLB grammar to the AST:

- The `<seq>` non-terminal should correspond to `Do` if and only if you end up
  parsing more than one semicolon-separated expression.
- The `<infix1>` and `<infix2>` non-terminals can produce `Eq`, `Lt`, `Plus`,
  and `Minus` primitive calls.
- The first `ID` case in the `<term>` non-terminal should produce `True` on the
  identifier `true`, `False` on the identifier `false`, `Nil` on the identifier
  `nil`, and `Var id` on other identifiers.
- The second `ID` case in the `<term>` non-terminal should produce either `Call`
  or a primitive. You can use the provided `call_or_prim` function to decide
  which one to produce.
- Feel free to ask us if you're not sure what AST you should produce in another
  case!
  
We've provided one other helper function: `consume_token` checks to see that the
head of a token list is what you want it to be, returning the tail of the list
if it is and raising an error otherwise. We've also provided a few `parse_`
functions to serve as a starting point for the parser. You shouldn't need to
change the top-level `parse_program` function, but you'll need to fill in the
bodies of `parse_defns` and `parse_expr` and add additional non-terminal parsing
functions.
  
## Testing

We've extended the tester to support programs in the new syntax. You can write
MLB-formatted examples either by:

- Putting `.mlb` files in the `examples` directory
- Writing a tab-separated `examples/mlb-examples.tsv` file. This file is
  tab-separated instead of comma-separated because unlike our Lisp-like syntax,
  MLB uses commas pretty extensively.

Note that in general, the interpreter and the compiler will give the same result
on all of your programs! You'll probably want to write `.out` files, or include
expected output in the `.tsv` file, to make sure your parser is actually
working. These work exactly the same as with `.lisp` files.

On this homework more than on previous ones, it may be useful to run your
functions in an OCaml shell. You can do that by running `dune utop` from the
`hw7` directory, then entering e.g.

```
> open Mlb_syntax.Tokenizer;;
> open Mlb_syntax.Parser;;
> tokenize "1 + 3" |> parse_program;;
```

## A word on associativity

With the grammar specified above, the MLB expression
`2 + 3 + 4`
will parse to something like (in S-expression syntax):
`(+ 2 (+ 3 4)`.

This is a little different from what we'd usually expect: addition is generally
defined to left-associative. Most languages parse that same expression to:
`(+ (+ 2 3) 4)`

For addition, this doesn't really matter--since it's associative, those
expressions evaluate to the same thing. This can lead to weird behavior on
subtraction, though: the expression
`10 - 3 - 2`
should probably evaluate to `5`, but if you implement the grammar as specified
above it will instead evaluate to `9` (i.e., `10 - (3 - 1)`).

If you finish your parser early, try to fix this! There's more than one way to
do it, but one way to get started would be to take a look at the `<seq>` and
`<rest-seq>` non-terminals, which are used to get a list of expressions. Could
you do something similar to get a list of terms, then transform the list into an
AST of the correct shape?

There's no extra credit available for doing this--it's just for "fun."
