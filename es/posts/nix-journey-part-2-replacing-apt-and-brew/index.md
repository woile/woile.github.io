<!--
.. title: Nix journey part 2: replacing apt and brew
.. slug: nix-journey-part-2-replacing-apt-and-brew
.. date: 2023-01-08 14:34:49 UTC
.. tags: rust, nix, flake, package manager, apt, brew
.. category: nix
.. link:
.. description: Moving away from brew and apt, to welcome nix and all it's benefits
.. type: text
-->

Even if I still cannot do much with [nix](https://nixos.org/), it still provides more advantages over other package managers:

- Multi-platform (mac, linux, etc.)
- Supports side-by-side installation of multiple versions of a package
- Makes it trivial to share development and build environments
- Nix ensures that installing or upgrading one package cannot break other packages
- It has the biggest database of packages (over 80.000 packages)
- I can run other people's commands, for example if I clone a repo and it says "run this nix command to have a development environment", then it doesn't matter if I don't know, I have already started using it.

A common situation I often run into, is writing shell scripts for linux and mac, where `grip` or `sed` are used.
On linux, they are called GNU `grep` or GNU `sed`, and they are not the same as in mac (freebsd version). Depending on the version, they may use different arguments.

We are going to see how can we avoid this by using `nix`. Even without using complicated features, it can make your CI system more reproducible.

Remember, `nix` is 3 things at the same time: an OS, a package manager and a language.

This post is about the **package manager**. I don't have much interest in the language, yet. Though more and more, I think I'll have to learn it.

Let's start by acknowledging a source of confusion:

**There is an old interface with counterintuitive commands** (`nix-env -iA ...`, `nix-shell -p ...`), which I found hard to remember, and I don't get why the "commands" start with a dash (`-`). I'm used to cli's doing `cli <command> [--options]`. Nowadays, there's a new cli called just `nix`. Let's see if we can do everything with it.

And make sure you have [installed Nix: the package manager](https://nixos.org/download.html) in your system. The installation is straightforward. I was personally blocked, because at some point in my dotfiles I was hardcoding the `PATH`, making nix never appear 🤦‍♂️.

And [enable flakes](https://nixos.wiki/wiki/Flakes#Enable_flakes).

There's also a [new installer by determine systems](https://github.com/DeterminateSystems/nix-installer), which is quite good.

## Installing packages

Install a package like on `brew` or `apt`.

```sh
nix profile install nixpkgs#htop
```

See also the [profile install command reference](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-profile-install.html).

In the old version of nix, we would run:

```sh
nix-env -iA nixpkgs.htop
```

Nix forces us to specify a "repository" (or "namespace") when installing a package (`nixpkgs`), which could be different, like github. And I think this is a good thing. From my understanding, nix doesn't care where the package is, because each package has a lock file, tracking all the dependencies. Okay, it could be a problem if one of the "repositories" is down, but using `nixpkgs` mainly and github for niche packages should be fine.

### What are profiles?

Disclaimer: I may be wrong on this, I'm starting to understand it.

The way to see `profiles` is like, "your user's packages". `nix profile` links packages to your `~/.nix-profile/`. You can specify other's profiles by using the flag `-p`.

You can find more in the [package-management section of the manual](https://nixos.org/manual/nix/stable/package-management/profiles.html) and [the profile command reference](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-profile.html)

## Searching packages

```sh
nix search nixpkgs#htop
```

Check the [search command reference](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-search.html)

We see again `nixpkgs`, because we have to let nix know from where, and then what we are looking for (`htop` in this case). To remember the word, I split it like this: `nix-p-k-gs`.

For example, I've made a flake package, hosted on github, and you can search what is offering, by specifying the "repository" only (no `#`):

```sh
nix search 'github:woile/wpa_passphrase_rs'
```

You can also search packages on [nix search index](https://search.nixos.org/packages?channel=22.11&show=htop&from=0&size=50&sort=relevance&type=packages&query=htop), but the commands shown are for the old nix interface, using `nix-env` or `nix-shell`.

Also, you can provide a regex like `firefox|chrome`, run `nix search --help` for more examples.

## Removing packages

Now this is a bit tricky, to remove you cannot type `htop`, you have to specify which dependency you want to clean. I think this is because you can have multiple versions of the same program. Also, one of your packages may depend on the version of another package, and if you also installed another version of the same package, and if you remove both, the original program that depends on one of them may break.

The solution to this is to list the installed packages in your profile, and then remove by position of said program.

```sh
nix profile list
```

```sh
nix profile remove 4
```

Check the [profile remove command reference](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-profile-remove.html).

## Open a package on a shell

This can be useful to test in isolation without installing a package in your profile.

```sh
nix shell nixpkgs#htop nixpkgs#gnused nixpkgs#youtube-dl

sed --help
htop --help
youtube-dl --version
CTRL+D # exit
```

## Nix Package Tool (npt)

Because I'm not used to most of the seen commands, I built a thin abstraction on top of `nix` called [npt](https://github.com/woile/npt). Which aims to be a humble succesor to `apt`. It also requires less characters to use it.

The installation, as we've seen before, can be done by running:

```sh
nix profile install 'github:woile/npt#npt'
```

And then run `npt --help` and check the commands, I hope it helps the transition to nix.

Now you can install packages by doing:

```sh
npt install htop github:woile/wpa_passphrase_rs#wpa_passphrase
# or npt i
```

It's still a work in progress, but a good start. I want to add the ability to show the executed nix commands, as a way of learning nix.


## Reproducible scripts

Remember when I said "even if you don't know much, someone else might", and having nix helps for this? and remember when I talked about my problems with `sed` and `grep`?

Turns out, nix can help in both of these situations, someone can write a reproducible shell script which you would execute, and even without knowing much, it would work.

A minor problem is that we cannot use flakes yet, meaning we cannot run `nix shell` and instead, we have to rely on `nix-shell`. But it's coming, see [#5189](https://github.com/NixOS/nix/pull/5189), [#4715](https://github.com/NixOS/nix/issues/4715).

In the meantime, let's try to solve the issue with what we have.

```sh
touch gnu-example.sh
chmod +x gnu-example.sh
vim gnu-example.sh
```

And paste the content of this script:

```sh
#! /usr/bin/env nix-shell
#! nix-shell gnused gnugrep

grep -V
sed --version
```

If run `./gnu-example.sh`, it would work both on linux, mac and probably also on freebsd.

Take a look at this other example, you can install a specific version of python and even dependencies.

```python
#! /usr/bin/env nix-shell
#! nix-shell --pure -i python -p "python38.withPackages (ps: [ ps.django ])"

import django
print(django.__version__)
```

This opens the door to replace `pyenv` and any `virtualenv` you will ever need.


Imagine creating a nix file specific to your project with its dependencies, which loads a shell with the dependencies when you navigate to the project folder automatically. Yes, you can say goodbye to any version manager (`pyenv`, `nvm`, etc).

You can read more about building a `shell.nix` in the [nix.dev tutorial](https://nix.dev/tutorials/declarative-and-reproducible-developer-environments). But keep in mind that `shell.nix` is being replaced by flakes.

## Flakes

Flakes are becoming the universal way of doing things in nix. [Creating shells](https://github.com/woile/wpa_passphrase_rs/blob/main/flake.nix#L19-L22), build commands, [compiling your source code](https://github.com/woile/wpa_passphrase_rs/blob/main/flake.nix#L17) or [creating ISO images](https://github.com/woile/rpi-iso-flake/blob/main/flake.nix#L22).

And there's a whole set of new tools making use of flakes that allow you to build dev shells, like [devenv](https://github.com/cachix/devenv) or [flox](https://github.com/flox/flox).

An exciting future is ahead!

I hope you've learned something with this post, and if you liked it, please let me know in the comments section below or tag me on hachyderm [@woile](https://hachyderm.io/@woile).
