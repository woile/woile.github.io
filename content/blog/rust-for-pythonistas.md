+++
title = "Rust for pythonistas"
date = 2019-05-28
tags = ["python", "rust"]
aliases = ["/posts/rust-for-pythonistas"]
draft = true
+++

# RUST FOR PYTHONISTAS

## Data structures with typing

| Data structure | Python             | Rust                    |
| -------------- | ------------------ | ----------------------- |
| number         | `num = 1`          | `let num = 1; `         |
| string         | `word = "avocado"` | `let word = "avocado";` |
| tuple          | `point = (1, 2)`   | `let point = (1, 2);`    |
| list | `my_list = [1,2,3]` | `let my_list = vec![1,2,3];
| dict | `` | `let info = HashMap::from([("name", 0.4), ("foo", 0.7)]);`


## builins

| Python               | Rust                            |
| -------------------- | ------------------------------- |
| `print("holis")`     | `println!("holis")`             |
| `map`                | `a_vector.into_iter().map()`    |
| `filter`             | `a_vector.into_iter().filter()` |
| `functools.reduce`\* | `a_vector.into_iter().fold()`   |

- not a builtin but still useful

## Use one variable

Because of immutability and [borrowing][borrowing], try not to spread variables around.
This basically means, do not spread the content of a variable into multiple variables.
This is not a problem with native data structures, but it's easy to forget about it.

In rust something like this will fail:

```rust
let mama = String::from("pipo");
let moma = mama;
println!("{} {}", mama, moma);
```

Why? Security and robustness.

## Strings

`str` is not what we would normally refer to as a `str` in python, it is a string slice,
and something like `"hello human"` is a string literal.
In rust, string slices are immutable,
It does not map well to python's `str`.
Instead the type `String` is the one that has useful functions.

```rust
let name = "jon" // literal string
let name = name.to_string() // String type
// we could also do:
let name = String::from(name)
```

Now that our string has been cast to the type `String` we can start doing some operations on it.

### Immutability

What does this mean?

[integers]: https://doc.rust-lang.org/book/ch03-02-data-types.html#integer-types
[strings]: https://doc.rust-lang.org/book/ch08-02-strings.html
[tuples]: https://doc.rust-lang.org/book/ch03-02-data-types.html#the-tuple-type
[borrowing]: https://doc.rust-lang.org/book/ch04-02-references-and-borrowing.html
