<!--
.. title: Secret management for the layman
.. slug: secret-management-for-the-layman
.. date: 2024-11-13 19:55:52 UTC
.. tags: age, secret management, security
.. category: devops
.. link:
.. description: How I manage secrets as a solo dev, using age and make, and a bit of nix
.. type: text
-->

For a long time, I've been debating myself how to properly handle secrets in a convenient, cheap and reproducible fashion.

I run a small website: [reciperium.com](https://www.reciperium.com) (check it out!) and I don't want to depend too much on the cloud.

Most of the available tools have the following problems:

- Hard to setup
- Hard to integrate with your infra
- Hard to communicate / share with teammates (you can give access but they still have to discover the secrets, and build the files)

I've developed a straightforward solution using `age`, and `git`.

- Secrets are stored as `.age` files in the `git` repo
- Supports multiple users

I call this workflow **"tracked secrets"**.

## Setup

First thing, prevent your private key from being leaked into git.

For that we add to our `.gitignore` the private keys:

```
*.key
```

If you use [nix](https://github.com/DeterminateSystems/nix-installer), you can set up a development environment with all the dependencies needed. In my case, I use `just` and `age` for this.

```nix
{
  description = "My Application";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };å
  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          ...
        }:
        {
          devShells.default = pkgs.mkShell {
            name = "reciperium";
            buildInputs = [
              pkgs.age
              pkgs.just
            ];
            shellHook = ''
              just --list
            '';
          };
        };
    };
}
```

You can also configure [direnv](https://direnv.net/), to load the nix dependencies, as soon as you `cd` into the directory.
This has been a powerful new method in my development toolkit.

## Interface

The commands abstract we are gonna use are the following:

```sh
# Create new key and add it to the recipients
sec__new-key

# Decrypt ALL secrets
sec__decrypt

# Encrypt ALL secrets
sec__encrypt
```

## Workflows

With those 3 commands we can support several different workflows:

### Initializing my host

The commands to be executed for this workflow should be:

```sh
sec__new-key
```

This should create a `me.key` and populate `recipients.txt` with the public key.

> If working on an existing repository, then I should create a commit, push the changes to git and ask to a colleague to encrypt the secrets again (after doing a pull)

### Encrypting all the secrets

The command to be executed:

```sh
sec__encrypt
```

This command can either encrypt everything necessary or it can be split into multiple commands internally.
It should encrypt with all the recipients present in `recipients.txt`.

### Decrypting all secrets

```sh
sec__decrypt
```

It should decrypt everything in the **right** place. And the user is ready to work!

### Creating a secret for a CI

One of the cool benefits of this approach, is that we can integrate it with our CI.

```sh
sec__new-key github
sec__encrypt
```

That should generate a `github.key`, and it should populate the `recipients.txt`. You can upload the `github.key` as a secret and your pipelines are ready to use it!

The second command encrypts everything again.

## Implementation example

Let's say we have a repository with our infrastructure. It has 2 folders, one with terraform code. And another with a docker-compose, which gets deployed to the server using docker-swarm.

```sh
app
├── infra-tf
│   ├── main.tf
│   └── terraform.tfvars
└── stack
    ├── .env
    └── docker-compose.yaml
```

The secrets of our application are `terraform.tfvars` and `.env`.

As I said, I've been using `just` for managing the commands, but you can use shell scripts or `make`.

Let's take a look at the `justfile`:

```makefile
# Create a new private key and store public in recipients.txt
sec__new_key name="me":
    test -f "{{name}}.key" || age-keygen -o "{{name}}.key" && age-keygen -y "{{name}}.key" >> recipients.txt

# Decrypt ALL secrets
sec__decrypt:
    age -d -i me.key stack/stack.env.tar.gz.age | tar xvz
    age -d -i me.key infra-tf/infra-tf.tar.gz.age | tar xvz

# Encrypt ALL secrets
sec__encrypt: _sec__encrypt__infra _sec__encrypt__stack

# Encrypt terraform.tfvars
_sec__encrypt__infra:
    tar cvz \
        infra-tf/terraform.tfvars | \
        age -R recipients.txt > infra-tf/infra-tf.tar.gz.age

# Encrypt the stack environment files
_sec__encrypt__stack:
    tar cvz \
        stack/.env \
        age -R recipients.txt > stack/stack.env.tar.gz.age
```

Okay, let's recap. For creating a private key for your current host:

```sh
just sec__new_key
```

The "new key" command is self-service, a user pulls the repo, runs the `just sec__new_key`,
and then they push. Another user, with access to the secrets, runs the encrypt again. And finally, the original
user pulls the latest commits, so they can use decrypt locally.

For encryption, we run:

```sh
just sec__encrypt
```

And to decrypt:

```sh
just sec__decrypt
```

Finally, we want to create a secret for our CI

```sh
just sec__encrypt github
```

We can also on-board other users, but it involves sending the private key to them, which can be cumbersome.

```sh
just sec__encrypt lara
```

## What to do with the private key?

After running `just sec__new_key`, we have a `me.key`. You can store a copy in your secret manager.

I personally use `gopass`, but there are many, like `1password` or `bitwarden`.

## Potential improvements

How can we handle different environments?

One option is to have a `secrets` folder, with the different environments there.

```sh
secrets/
├── dev/
├── preview/
└── prod/
```

And we could make just accept different parameters when calling the commands:

```sh
just sec__encrypt prod
```


## Final comments

Even though, I've seen a lot of people share their nixos configuration publicly, including their encrypted secrets, I still wonder if it's safe, and if so, why is it not used widely?
I want to believe it's safe, and I know that if the secrets get leaked, I'll have to update them all.
The plus side, is that you know where they are, and you can probably write comments on how to retrieve or generate them again, becaues it's just files.

What do you think of this approach?

Thanks for reading
