<!--
.. title: Nix journey part 3: learning nix-lang
.. slug: nix-journey-part-3-learning-nix-lang
.. date: 2023-01-14 13:26:08 UTC
.. tags: nix, flake, nix-lang
.. category: nix
.. link:
.. description:
.. type: text
-->

I started reading the [nix-language](https://nix.dev/tutorials/nix-language) tutorial that helps you understand the [nix-lang](https://nixos.org/manual/nix/stable/language/index.html).

The explanation that has made more sense so far is:

> If you are familiar with JSON, imagine the Nix language as _JSON with functions_.
>
> Nix language data types _without functions_ work just like their counterparts in JSON and look very similar.

And here's a comparison:

nix:

```nix
{
  string = "hello";
  integer = 1;
  float = 3.141;
  bool = true;
  null = null;
  list = [ 1 "two" false ];
  attribute-set = {
    a = "hello";
    b = 2;
    c = 2.718;
    d = false;
  }; # comments are supported
}
```

json:

```json
{
  "string": "hello",
  "integer": 1,
  "float": 3.141,
  "bool": true,
  "null": null,
  "list": [1, "two", false],
  "object": {
    "a": "hello",
    "b": 1,
    "c": 2.718,
    "d": false
  }
}
```

I like what I see. Why not making it more similar to json though?

Here I'm listing my thoughts while reading. I hope this feedback can help improve the docs (I can't yet as I literally know nothing, taking it as a brain dump):

1. Why no comma separated arrays? My hand automatically tries to add commas when making a list. Maybe an explanation would help to avoid people's complaints like me.
2. JSON with comments + functions? Sounds like a plan
3. Pure language, meaning no interaction with the outside world, except when reading files. I like this
	1. Does it mean there's no `print`? is the output of executing nix a `print`?
4. I bet I'll have to learn some builtin functions to understand it better
5. String concatenation is straightforward, nothing weird here ``"a" + " " + "b"`` works as expected. Good.
6. `let .. in ...` is weird, are they like function declarations? Strange way to create a local scope.
7. semicolons `;` only  after initializing variables.
8. Could this language be used to replace `yaml` and other configuration formats? What about `toml` with functions? Okay, I'm derailing, back to reading.
9. It's not very intuitive, let's see some valid samples
```nix
let
  a = {
    x = 1;
    y = 2;
    z = 3;
  };
in
a.x + a.y
```
it doesn't end with semicolon, outputs: 3. Ok
Now the `with` + assignment
```nix
let
  a = {
    x = 1;
    y = 2;
    z = 3;
  };
in
b = with a; {t = x; u = y;}
```
error. Solution? wrap with `{}` and introduce semicolon
```nix
let
  a = {
    x = 1;
    y = 2;
    z = 3;
  };
in {
  b = with a; {t = x; u = y;};
}
```
Works. Whatever. How do I add `b.x` + `b.y`?
```nix
let
  a = {
    x = 1;
    y = 2;
    z = 3;
  };
in {
  b = with a; {t = x; u = y;};
  b.t + b.u
}
```
Nope, maybe the `let.. in...` I just learned?
```nix
let
  a = {
    x = 1;
    y = 2;
    z = 3;
  };
in {
  let b = with a; {t = x; u = y;};
  in
  b.t + b.u
}
```
Nope. Couldn't find an explanation, maybe it's not allowed.
10. Why cannot coerce an int into a string? I don't see an explanation. Types could implement like a `Into<string>` trait, right? Maybe there's a good reason, but I think this can be useful for naming things `[ home-1 home-2 ]`
11. Integration with fs is dope.
12. How are search path populated? `<nixpkgs>` works, but `<path>` does not. Are there other variables? Good thing it's not recommended to use them.
13. `Indented strings` are fantastic. The equal amount of space trimmed is perfect for writing scripts that look good, without compromising style.
```nix
let
  uglyyaml = ''
  holis:
    machines:
      - m1
      - m2
  '';
in
  uglyyaml
```


Well I'm done, it was worthy. After reading the quick overview I understand much more. So much I was able to create my own shell from a flake. This is the sample `flake.nix`:

```nix
/*
  This flake provides a shell where you can add flakes

  Adding dependencies:
    1. Add your flake repository as an input url
    2. Add the repository name to the function signature
    3. Add your repo's package to buildInputs

  Opening shell with your deps:
    ```sh
    nix develop
    ```

  For compatibility with nix-shell add the template compat:
    ```sh
    nix flake new . -t templates#compat
    ```
*/
{
  description = "Build your own shell";
  inputs = {
    utils = { url = "github:numtide/flake-utils"; };
    wpa_passphrase_rs = { url = "github:woile/wpa_passphrase_rs/main"; };
    # point 1: add repo url
  };
  # point 2: add to function
  outputs = { self, nixpkgs, utils, wpa_passphrase_rs }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShell = with pkgs; mkShell {
          # point 3: add package
          buildInputs = [
            gnugrep
            gnused
            wpa_passphrase_rs.defaultPackage.${system}
          ];
        };
      }
    );
}
```

Run `nix-develop` and you'll have a shell with your dependencies.
Question: How do I keep using my own shell?

You can copy-paste and extend that sample into your projects. I asked on github if it could be merged [#59](https://github.com/NixOS/templates/issues/59). Again, as a newbie in nix I don't know if it makes sense from nix perspective. Am I supposed to be doing things this way in nix?

What I've been thinking is that I would like a `cli` that adds the code for me to the `flake.nix`:

```sh
$ flakectl add dep github:woile/wpa_passphrase_rs
Searching packages...
1. packages.x86_64-darwin.wpa_passphrase (0.1.0)

Choose package to add [int]:
1

Does the package provide a service? [y/N]
n
```

And to add more things:

Environmental variables (maybe even encrypted using [agenix](https://github.com/ryantm/agenix)):
```sh
$ flakectl add env SRC_FOLDER=foobar
Adding variables to your flake.nix...

After running `nix develop` or `nix-shell` to see your variable run:
`echo $SRC_FOLDER`
```

Language support

```sh
$ flakectl add lang python rust
Adding support for python and rust to your flake.nix...

Use `nix build py` to create a python wheel
Use `nix build rs` to compile the rust code.
```

Commands

```sh
$ flakectl add script deploy --bang py
Adding `deploy` script to your flake.nix...

Use `nix run deploy` to execute the script.
```

Would something like this make sense as output?

```sh
$ tree scripts
scripts/
└── deploy.nix
```

And maybe some other ways to manipulate the flake itself. This way I can "ask" for the things I want, and later take a look at the result of the flake itself, without having to know much of nix-lang, and learning on the way.

The question is: What are common things people need?

It could be done with rust implementation of the AST parser [rnix-parser](https://github.com/nix-community/rnix-parser). Unfortunately I don't have much time to dig into this idea. Let me know if you do!

Thanks for reading again.

Find me on [@woile@hachyderm](https://hachyderm.io/@woile)
