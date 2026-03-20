+++
title = "Sharing passwords using gopass, git and gpg"
description = "Share secrets between team members, manage your personal password, multi device, gpg, happiness."
date = 2019-03-18
tags = ["security", "password manager", "encryption", "gpg"]
aliases = ["/posts/sharing-team-secrets"]
+++

> Tired of storing your passwords in unreliable but convenient places?

> Tired of sharing password across unreliable platforms? slack, notes,
  etc

> Tired of having your team passwords in no specific place?

If you have answer to any of this questions with a yes, then you might find
this post useful. 

<img src="https://media.giphy.com/media/5VKbvrjxpVJCM/giphy.gif">

## Background

For quite some time, I\'ve been trying to solve this problem I had in my
mind. I was looking for a way to store my passwords (I\'ll refer to them
as secrets also) in a secure way. But also, I wanted these features:

- Storing passwords in the cloud
- Easy to synchronize between devices
- Easy to share between teammates (groups)

The solution I found was [gopass](https://www.gopass.pw/).

## How it works

Basically [gopass](https://www.gopass.pw/) is like
[pass](https://passwordstore.org) (the unix password manager) with an
extra pair of batteries.

Among others, the features it has, relevant to me, are:

1.  Uses **gpg** for secrets encryption.
2.  Uses **git** for secrets synchronization.
3.  Multiple password\'s **stores** (personal, company, etc).
4.  Each store can point to a different repository.
5.  Support for **multiple people** per store, called recipients in the
    jargon.

Even though it lacks a bit in documentation, the commands just do
what\'s expected of them. So don\'t be afraid to play with it.

Regarding gpg, it makes me glad to start wrapping my mind around it, and
gopass using it, well, makes my day :)

The only drawback I found is the lack of official windows support. I
don\'t know if it works or not in windows.

## Installation

You can check the website\'s
[installation](https://www.gopass.pw/#install) or you can go to a more
in depth explanation in gopass
[repo](https://github.com/gopasspw/gopass/blob/master/docs/setup.md).

## Usage

First of all, we are gonna need a gpg key. To create one, gopass it\'s
not needed. Instead, we are gonna use gpg cli that should be in your
system if you have installed gopass.

**How does gpg work?**

In the context of gopass, we are gonna use the public and private keys
provided by gpg.

Imagine you have an infinite amount of boxes (public key), that once
they are closed, they can only be open with a key that only you have
(private key).

From this analogy, we can conclude 2 things:

1\. You **can distribute your public keys** and let anyone encrypt
information with it. Let\'s say I give boxes to friends, they put
something inside and close it. That\'s it, only I will be able to open
it. And of course, I can also encrypt my stuff, in case some is sniffing
around.

2\. **Private keys are really important**, keep them safe, don\'t lose
them, and make a backup. You can use an encrypted pendrive, a paper note
in a safe place, or a [yubikey](https://www.yubico.com/). Would be nice
if companies give yubikeys to their employees, right?

**Creating a key**

Simple as following the prompt that appears after typing the command. If
you don\'t know what to fill, use the default values.

``` bash
gpg --full-generate-key
```

And check the generated key

``` bash
gpg -k
```

### Initializing gopass

Easy as typing

``` bash
gopass init
```

This will set up some stuff and will create the default store.

I recommend adding the autocomplete to your terminal

``` bash
echo "source <(gopass completion bash)" >> ~/.bashrc
```

### Using gopass

Gopass works in a \"unix\" like way. You\'ll have a tree (folders) where
the leaves are encrypted files.

``` 
gopass
    ├── my-company
    │   └── pepe@my-company.com
    └── personal
        └── pepe@personal.com
```

Let\'s begin by **inserting** a secret.

``` bash
gopass insert personal/twitter/santiwilly
```

It will show a prompt and you\'ll have to fill the password twice. The
structure I follow is this (most of them optional)
`{store}/{org}/{env}/{username or email}`.

Now let\'s **list** our secret, by simply doing

``` bash
gopass ls
```

We should now see, something like this.

``` 
gopass
    ├── my-company
    │   └── pepe@my-company.com
    └── personal
        ├── pepe@personal.com
        └── twitter
            └── santiwilly
```

Perfect!

Let\'s continue. I\'m just gonna throw you the commands, they don\'t
have any complexity.

**Show password**

``` bash
gopass personal/twitter/santiwilly
```

**Copy password to clipboard**

``` bash
gopass -c personal/twitter/santiwilly
```

**Generate random pass**

``` bash
gopass generate my-company/anothername@rmail.com
```

**Search secrets**

``` bash
gopass search @gmail.com
```

### Using stores

Here\'s were my journey got a bit complicated, as I mentioned the docs
are not necessary bad, but you can get lost, maybe the website could be
organized a bit better. So I ended up creating multiple docker
containers and started playing around.

Stores (AKA **mounts**) let you group your passwords. Example:
`personal`, `company`. Each one can live in a different repository, and
you could potentially, share `company` with your peers.

**Initialize new store**

Creates a new store located at `~/.password-store-my-company`.

``` bash
gopass init --store my-company
```

**Add git remote to store**

``` bash
gopass git remote add --store my-company origin git@gh.com/Woile/keys.git
```

**Clone existing store**

Let\'s say you move to another computer, now it\'s where gopass starts
to shine. Whether you use the same private key (imported in different
computers) or you choose to have a key per machine, to clone a repo, you
just need access to it.

``` bash
gopass clone git@gh.com/Woile/keys.git my-company --sync gitcli
```

It\'s important to specify `gitcli` as the `sync` method. Otherwise
gopass won\'t know how to synchronize the secret (it will use `noop` by
default). Gopass provides other sync methods but I haven\'t checked
them.

Solutions that provide a free private repo are:

- [gitlab](https://www.gitlab.com)
- [github](https://github.com)
- [bitbucket](https://bitbucket.org/product)

**Removing existing store**

To avoid having issues with gopass, first we need to unmount the store.

``` bash
gopass mounts umount my-company
```

Now that we\'ve done this, it\'s safe to remove the folder.

``` bash
rm -rf ~/.password-store-my-company
```

### Synchronization

In gopass, sync usually means `git pull` and `git push`, maybe also
commit but I\'m not sure. Usually the commits are done on
`gopass insert`.

**Synchronize with git remotes**

``` bash
gopass sync
```

**Synchronzing a single store**

``` bash
gopass sync --store my-company
```

### Team sharing

We are finally on the last and most fantastic part, sharing secrets with
people.

Suppose we have a colleague with an email `logan@pm.me`. This person has
already generated a gpg key, for that email, in they machine.

Logan then, must **export the public key** and send it to us.

``` bash
gpg -a --export logan@pm.me > logan.pub.asc
```

It\'s okay, public keys can be shared in untrusted environments. If you
are still not convinced, try [send](https://send.firefox.com) from
firefox. Keep in mind that people share their public keys in keyservers,
like [opengpgkeyserver](https://pgp.surfnet.nl/).

**Adding public key into gopass**

We have the public key, now it\'s time to **import** it into our local
gpg keyring.

``` bash
gpg --import < logan.pub.asc
```

And lastly, we need to **add the new key to a gopass store**.

``` bash
gopass recipients add logan@pm.me
```

You\'ll see a prompt with all of your stores. Choose the one you want,
and it will re-encrypt your secrets with the new public key (plus the
existing ones).

And that\'s it, we are done. You can of course remove recipients, but
I\'ll let you do the search, tip: `gopass recipients --help`.

## Conclusion

I have created a gopass [cheat
sheet](https://woile.github.io/gopass-cheat-sheet/) with these commands
and a [presentation](https://woile.github.io/gopass-presentation/) to
convince your colleagues.

<img src="https://media.giphy.com/media/3ohhwo81vLfGfDsDrG/giphy.gif">

Gopass is an awesome tool to include in your toolbelt. Unfortunately, it
is not that easy for non-developers, but still possible.

Some extra tools I use to enhance my gopass experience are:

[Android password
store](https://github.com/zeapo/Android-Password-Store)

I suggest installing it using F-droid, you\'ll need OpenKey-chain to
create a new gpg key, and you already know how to add multiple
recipients to your stores.

[Gopass bridge](https://github.com/gopasspw/gopassbridge)

Browser extension for Firefox or Chrome that let\'s you access your
stores.

[Gopass UI](https://github.com/codecentric/gopass-ui)

Electron based UI wrapper for your gopass on the command line. It makes
your life easier by providing a rich graphical user interface to search
and manage your secrets.

Any feedback is welcome, as I\'m no security expert and I\'d be glad to
have a better and more secure workflow.

Thank you for reading.

Note: I\'ve added some random memes to ease the reading.
