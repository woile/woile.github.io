<!--
.. title: Nix journey part 1: creating a flake
.. slug: nix-journey-part-1-creating-a-flake
.. date: 2022-12-30 16:04:18 UTC
.. tags: rust, nix, flake, package manager
.. category: linux
.. link:
.. description: How to create a flake and use it from another shell
.. type: text
-->


I've started building my own home media center, and I thought it would be a good idea to learn something new and try to make it reproducible, thus I thought of [nix](https://nixos.org/) for this. Nix is an operating system (which we won't care now), a language (also don't care for now), and a **package manager**.
We are gonna focus on the package manager part alone, which is already a lot for my brain. This package manager works on mac and linux, and it already has many packages available (bye bye interop problems between mac/linux?)

The first thing I needed for my raspberry pi was to create a PSK password using `wpa_password`, and I tried to run it inside a nix shell on my mac, which didn't work, because `wpa_password` doesn't run on a mac.
This was a good opportunity to write something fast, and to make it reusable and reproducible from any unix OS using nix.

## Objectives
1. Create a nix package for `wpa_password` (a nix flake)
2. Use `wpa_password` in my home-media project. I want to jump into a shell with the `wpa_password` from any unix os, mac or linux (freebsd at some point?)

## Creating a nix package

I ended up writing the utility in rust, which took me a bunch of hours, the repo [wpa_passphrase_rs](https://github.com/woile/wpa_passphrase_rs) contains the project finalized.

After a lot of reading, and wrapping my mind around nix, which I had 0 knowledge before, everything points out that flakes are the new kid in town, and that's what I should use in my project.

I have a take on nix status, which may need corroboration: nix is moving away from the old way to the new (flakes) way, and there are many outdated posts, and commands. Many commands that fit the pattern `nix-*` are no longer used, and instead people now use the new `nix <command>` instead. For example, things like `nix-shell` are not used much anymore.

Going back to the nix flake, If you have [installed nix](https://nixos.org/download.html), **flakes must be enabled**, because it's an experimental feature.

For mac (which only supports multiuser installation):

```sh
echo 'experimental-features = nix-command flakes' >> /etc/nix/nix.conf
# you may use ~/.config/nix/nix.conf on linux
```

### What are flakes?

According to [nix's wiki](https://nixos.wiki/wiki/Flakes):

> Flakes allow you to specify your code's dependencies (e.g. remote Git repositories) in a **declarative way**, simply by listing them inside a `flake.nix` file.
> Each dependency gets pinned, that is: its commit hash gets automatically stored into a file - named `flake.lock` - making it easy to, upgrade it
> Flakes replace the nix-channels command and things like ad-hoc invocations of `builtins.fetchgit` - no more worrying about keeping your channels in sync, no more worrying about forgetting about a dependency deep down in your tree: everything's at hand right inside `flake.lock`.

Seems like we are gonna need two files: `flake.nix` and `flake.lock`.

The next step is to create the flake from a template. What available templates do we have? I wonder...

```sh
nix flake show templates
```

```
github:NixOS/templates/2d6dcce2f3898090c8eda16a16abdff8a80e8ebf
├───defaultTemplate: template: A very basic flake
└───templates
    ├───bash-hello: template: An over-engineered Hello World in bash
    ├───c-hello: template: An over-engineered Hello World in C
    ├───compat: template: A default.nix and shell.nix for backward compatibility with Nix installations that don't support flakes
    ├───full: template: A template that shows all standard flake outputs
    ├───go-hello: template: A simple Go package
    ├───haskell-hello: template: A Hello World in Haskell with one dependency
    ├───haskell-nix: template: An haskell.nix template using hix
    ├───hercules-ci: template: An example for Hercules-CI, containing only the necessary attributes for adding to your project.
    ├───pandoc-xelatex: template: A report built with Pandoc, XeLaTex and a custom font
    ├───python: template: Python template, using poetry2nix
    ├───rust: template: Rust template, using Naersk
    ├───rust-web-server: template: A Rust web server including a NixOS module
    ├───simpleContainer: template: A NixOS container running apache-httpd
    └───trivial: template: A very basic flake
```

Fantastic! Look at that! There's a python version and even a rust web server. The one I need is the rust template, let's use that one as a base.

```sh
nix flake init -t templates#rust
```

And that was it, it worked. This is going well. I can create a binary inside `./result/bin` by running

```sh
nix build
```

or use it by running

```sh
nix run
```

My mind is blown at this point 🤯


## Using the flake somewhere else

I couldn't find much about this, as I said, there's a mix of old and new information.
I think it clicked for me, when I realized that the `nix` command is new, and it's integration with flakes goes to its core (am I correct on this?).

Using the flake becomes straightforward.

```sh
nix shell 'github:woile/wpa_passphrase_rs'
```

And `wpa_password` will appear on my `PATH`.

```sh
wpa_password --help
```

And we can exit with a <kbd>CTRL</kbd> + <kbd>D</kbd>.

## What's next?

What's the right way to make it declarative? I want to have a file with the dependencies required for my home media project, and I'd like to jump into a shell with everything present.

Is there a different strategy for this?

How to use [NixOps](https://github.com/NixOS/nixops) to provision all my raspberries and any other machine that joins the fleet?

This [comparison between Ubuntu and Nix](https://nixos.wiki/wiki/Ubuntu_vs._NixOS) appears to be useful, I should read as well.

Please let me know in the comments section below or tag me on hachyderm [@woile](https://hachyderm.io/@woile)

Thanks for reading
