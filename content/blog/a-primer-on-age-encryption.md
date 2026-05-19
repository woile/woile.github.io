+++
title = "A primer on age encryption"
description = "Poking at age encryption. Exploring its simplicity, usage, and plugins, including TPM, SSH and FIDO2 support. Is encryption finally for everyone?"
date = 2026-05-12
tags = ["security", "secret management", "age"]
+++

I've been interested in [age] since it first appeared a few years ago (ca. 2020? Well, closer to a decade ago, how old am I?),
mainly, because of its promise of simplicity.

I'm a long time `gpg` user, but I'm one of those users that has no confidence in what I'm doing.
It does too many things which keep me confused, combined with poor docs and a cli that just doesn't feel intuitive.

And thus, [age] presented a good opportunity to adapt and make my setup simpler.

[age] is an encryption format, specified in [age-encryption.org/v1](https://age-encryption.org/v1) which focusing mainly on encryption and decryption.

I dipped my toes into `age` a while ago;
I published a blog post on how I structure the [secrets in a repository](./secret-management-for-the-layman) and,
as a side-effect, used `age` for that.

Now, I'm onboarding [agenix] into my NixOS configuration ([nix-config](https://github.com/woile/nix-config/)),
and wanted to explore the ecosystem a bit more.

This post is a side-effect of that exploration.

## Usage

For this section, I assume you have [nix](https://nixos.org/guides/how-nix-works/) installed, which works on Linux, Mac, WSL, even Steam Deck and containers.
If not, check the [nix-installer](https://github.com/NixOS/nix-installer#nix-installer).

Let's jump into a shell with `age` and its associated tooling.

```sh
# Just the age cli
nix-shell -p age

# age plugins we are going to use
nix-shell -p age-plugin-tpm age-plugin-fido2-hmac

# Drop yourself into a tmp dir for practicing
DIR=$(mktemp -d -t age-practice.XXXXXX) && cd "$DIR"
```

We are going to go through the main workflow, which is: creating a private key, encryption, and decryption.

Start by **creating a key**, and store its public key in `recipients.txt`

```sh
# Create keys
age-keygen -o "priv.key"

# Save public key to recipients
age-keygen -y priv.key >> recipients.txt
```

Which results in 2 files.

```sh
$ ls
.
├── priv.key        # private key
└── recipients.txt  # aggregated public keys
```

By "**aggregated public keys**", I mean the public keys that we are going to use to encrypt things.
Imagine you have 2 devices, instead of moving the private key around, you have one private key per device.
I'll go over this in the next section.

Now let's see **encryption and decryption** of an `.env` file.

```sh
# Init file
echo "API_KEY=unsafe" > .env

# Encryption
tar cvz .env | age -R recipients.txt > env.tar.gz.age

# Let's remove the env file and show what's in the current dir
rm .env && ls

# OBSERVE the shape of the age encrypted file
cat env.tar.gz.age
# age-encryption.org/v1
# -> X25519 VTfterDUb7cvb7nELDePn4ynbTi3+e6XumZsdL6PU3A
# ....

# Decryption
age --decrypt -i priv.key env.tar.gz.age | tar xvz

# Verify file
cat .env
```

Done! And with that, we covered `age`'s cli surface.

But that's not the end of the story, having a flying private key around just doesn't feel entirely right.
Especially if we are talking about the main key, which can decrypt all secrets passed around.
Is there another way? What about security keys? Let's take a look.

## Aggregating Public Keys

Here is what caught my eye: **the plugins**.

`age` interface might be simple, but the ecosystem is rich! It changed how I think about secrets and recipients. It's no longer about having a key that represents my identity, but instead, about devices that I have, and can access these secrets.

As I said before, we can encrypt something with multiple public keys, and whoever has one of the private keys can decrypt.

But when would you want this? Let's see…

- When you have multiple devices
- But imagine this: sharing secrets across your team, or organization
- Or, the solution I'm evaluating for [agenix]

[agenix] is a tool for NixOS, that leverages `age`, to distribute secrets across your hosts. You can choose which host(s) can access which secrets, by selecting the public keys that will encrypt the secrets.

This is a snippet of how it looks in practice:

```nix
let
  user1 = "ssh-ed25519 AAAAC3N...";
  user2 = "ssh-ed25519 AAAAC3N...";
  users = [ user1 user2 ];

  system1 = "ssh-ed25519 AAAAC3...";
  system2 = "ssh-ed25519 AAAAC3...";
  systems = [ system1 system2 ];
in
{
  "secret1.age".publicKeys = [ user1 system1 ];
  "secret2.age".publicKeys = users ++ systems;
  "armored-secret.age" = {
    publicKeys = [ user1 ];
    armor = true;
  };
}
```

Don't worry if it doesn't make sense, what you need to know, is that we list public keys for users and systems, and we choose which ones can access what.

In my case, I have 2 machines, and me (physically). An admin laptop and a VPS. And, the VPS is the consumer of the secrets.
The laptop (and I) should have access to the secrets the VPS will use.

To achieve this, I want to use the [TPM](https://en.wikipedia.org/wiki/Trusted_Platform_Module#TPM_2.0) module in the laptop, the SSH key generated by nix in the remote VPS, and finally, my SoloKey (a fido2 key).

```d2
laptop.TPM -> secrets
fido2-key -> secrets
vm.ssh -> secrets
```

Is this possible with `age`? Let's check one by one.

### TPM (Trusted Platform Module)

It's a chip in the CPU (or motherboard), available in most modern OEM hardware, that protects sensitive data.
It's similar to Apple's Secure Enclave.

How does it integrate with `age`?

Via the `age-plugin-tpm` (or `age-plugin-se` on Mac)

We drop into a shell with the module.

```sh
nix-shell -p age-plugin-tpm
```

And create a private key.

```sh
# Create key
age-plugin-tpm --generate -o tpm-identity.key

# Save public key to recipients
age-plugin-tpm -y tpm-identity.key >> recipients.txt
```

The `tpm-identity.key` created by the plugin contains the private key, but it's actually wrapped by the TPM module in the machine.
This means if an attacker steals the `tpm-identity.key` file, it is completely useless to them without physical access to your machine's hardware.

And because of the format used in the `tpm-identity.key`, `age` knows it needs to use the plugin to decrypt.
It's a simple format really, the text of the key starts with the name of the plugin.

```sh
cat tpm-identity.key
```

```sh
# Created: 2026-05-19 14:19:29.890241884 +0100 WEST m=+0.279063475
# Recipient: age1tag1qtf848pl66qhk7...

AGE-PLUGIN-TPM-1QGQQQKQQYVQQK...
```

If we were to run the same commands as in the [usage](#usage) section.
The only difference would be that we would use the `tpm-identity.key` to decrypt.

```sh
age --decrypt -i tpm-identity.key secrets.tar.gz.age | tar xvz
```

### SSH

SSH keys are supported by `age` from the get-go; you can use them directly. The SSH public key to encrypt, and the SSH private key to decrypt.

```sh
# Create pub and private key. (You will be prompted for a secure passphrase)
ssh-keygen -t ed25519 -C "mymail@example.com" -f ./ssh_ed25519

# 2 SSH keys: `ssh_ed25519` and `ssh_ed25519.pub`
ls | grep ssh_ed25519

# Add the pub key as a recipient
cat ssh_ed25519.pub >> recipients.txt
```

If we were to execute the commands from the [usage](#usage) section,
we would only change the key used, and instead we would directly use the private SSH key `ssh_ed25519`.

```sh
age --decrypt -i ssh_ed25519 secrets.tar.gz.age | tar xvz
```

### FIDO2 Security Key

By now, you might've noticed the pattern is the same:

1. Install plugin
2. Generate keys (priv & pub) using a plugin
3. Add the public key to the recipients list
4. Encrypt/Decrypt secrets

The `age-plugin-fido2-hmac` plugin is no different. It allows using your FIDO2 device (YubiKey, SoloKey, Nitrokey, etc) to create age keys.
Like the TPM plugin, it wraps the private key. And in order to decrypt, you'll need to touch the stick.

```sh
# Create the key, following the steps
age-plugin-fido2-hmac -g > fido2.key

# Add the pub key to the recipients
cat fido2.key | grep 'public key' | grep -oP 'age1.*' >> recipients.txt
```

And like before, we would decrypt just by pointing to the `fido2.key`

```sh
age --decrypt -i fido2.key secrets.tar.gz.age | tar xvz
```

Using the FIDO2 key is not strictly necessary, however, it brings me value as a **backup option**, stored in a secured location.
The TPM module will take care of the day to day operations, but if something happens to the laptop, it's useful to have a backup.

### Other Plugins

Besides the plugins I've covered, there are more, and you can probably find one for your use case.
These piqued my curiosity:

- `age-plugin-sss`: split keys and wrap them with different recipients using [Shamir's secret sharing](https://en.wikipedia.org/wiki/Shamir%27s_secret_sharing)
- `age-plugin-1p`: Use SSH keys stored in 1Password
- `age-plugin-yubikey`: YubiKey integration, although you can still use the `age-plugin-fido2-hmac` with a YubiKey

## Closing Thoughts

`age` has matured a lot since its conception, like fine wine.

It allows me to move with confidence, by understanding what's happening under the hood by betting on usability, without compromising on security.

In my next post, I'll cover [agenix] and how I integrate with my NixOS setup.

Let me know your thoughts. Thanks for reading!

[agenix]: https://github.com/ryantm/agenix
[age]: https://github.com/filosottile/age
