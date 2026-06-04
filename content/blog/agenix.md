+++
title = "NixOS with agenix"
description = "Onboarding agenix on my NixOS config"
date = 2026-06-04
tags = ["security", "secret management", "nixos", "age"]
+++

[agenix]: github.com/ryantm/agenix
[age]: github.com/filosottile/age
[nix-config]: https://github.com/woile/nix-config/
[vaultix]: https://milieuim.github.io/vaultix
[NixOS]: https://nixos.org/

I've been avoiding managing secrets in [NixOS] for a long time, when I started with `nix`,
I didn't fully comprehend how the solutions for secret management worked, so I left it as a future problem.

I started using `nix` in a MacBook a couple of years ago, then I ditched it for an OEM laptop, with… you guessed it… [NixOS]!
Toss a media center and a VM into the mix, all managed via NixOS; and secrets were bound to happen.

```d2
nixos -> vm
nixos -> laptop
nixos -> media-center
```

The time has finally arrived.

I chose [agenix], one of the most popular solutions for secret management.
Another popular option was `sops-nix`, but you have to use YAML, and I'm YAML fatigued, so pass.
To be fair, `sops-nix` is usually recommended for more complex scenarios, and mine is quite straightforward.

In this post, I'm gonna cover my mental model of how it works and finally, my expectations.
I'm not covering how to install `agenix`, which is already well covered in their [installation docs](https://github.com/ryantm/agenix#installation).

My setup is using nix flakes, so this write assumes so.

Conceptually, we can split [agenix] in these scenarios:

- Key management
- Secret creation
- Secret usage

## Key Management

This is the simplest part. Internally, [agenix] uses [age] to encrypt and decrypt secrets. I've written [a primer on age](./a-primer-on-age-encryption).
Not only you can set multiple recipients, but you can use SSH keys for encryption/decryption.

When the `openssh` module is enabled in NixOS, it **automatically creates some SSH key pairs on the host machine** under `/etc/ssh/`.
We can leverage the SSH keys to encrypt/decrypt secrets for a given host.
The recommended one being `/etc/ssh/ssh_host_ed25519_key`.

And for redundancy, you can create a main key, used on all secrets.

So the idea is, to **let each host, decrypt the secrets they need, using the SSH key, that they already hold.
And use the "main keys", for redundancy**, in case any of the host changes.
For example, if you recreate a VM, the SSH key will change, and you wouldn't have access to the encrypted secrets without a main key.

```d2
direction: right
vm.ssh -> api_key
laptop.ssh -> admin_password
main-key -> admin_password
main-key -> api_key
```

So we start by gathering our public keys:

```shell-console
$ # laptop public key
$ cat /etc/ssh/ssh_host_ed25519_key.pub
ssh-ed25519 AlAaApAtCop...

$ # vm public key
$ cat /etc/ssh/ssh_host_ed25519_key.pub
ssh-ed25519 AvAmAAC3N...

$ # main key
$ cat ~/.age/main.pub
age1mca4i2n7...
```

> 💡TIP
>
> For the main key, you can use a FIDO2 key,
> or the [TPM](https://en.wikipedia.org/wiki/Trusted_Platform_Module#TPM_2.0)
> module of your machine for extra security

## Secret Creation

Once we gather the public keys, we consolidate them in a `secretx.nix`,
which is **only used to generate secrets**, it's not imported into your NixOS configuration.

```nix
# secrets.nix
let
  laptop-host = "ssh-ed25519 AlAaApAtCop";
  vm-host = "ssh-ed25519 AvAmAAC3N"
  main-user = "age1mca4i2n7";
in {

}
```

And then we specify, for each secret, which keys to use.

```diff
# secrets.nix
let
  laptop-host = "ssh-ed25519 AlAaApAtCop";
  vm-host = "ssh-ed25519 AvAmAAC3N"
  main-user = "age1mca4i2n7";
in {
+  "api_token.age".publicKeys = [ main-user laptop-host ];
+  "server_password.age".publicKeys = [main-user vm-host ];
}
```

Finally, we use the cli provided by [agenix] to generate the secrets files (ending in `.age`) based on the `secrets.nix` file.

```sh
# run only if you are missing the cli
nix shell github:ryantm/agenix
```

```sh
agenix -e 'api_token.age'
agenix -e 'server_password.age'
```

Each time we run the command, `agenix` opens your default editor (via `$EDITOR`), you fill the password.
And after you save and exit, `agenix` will read the `secrets.nix`, read the recipients of the secrets, and encrypt accordingly.

This is a **keypoint: secrets are created via `agenix`**.

You don't create a file with the raw secret, and tell `agenix` to encrypt it.

```d2
direction: right
secrets config.'secrets.nix' -> create secret
create secret.'agenix -e api_token.age' -> secretfile.'api_token.age'
```

### Changing Directories

If you are like me, and want to choose where to place the `secrets.nix`,
you'll need 2 things. Specify the path in the nix code, and set the `RULES` env before running the `agenix` cli.

Example using the `security` directory:

```diff
- "api_token.age".publicKeys = [ main-user laptop-host ];
+ "security/api_token.age".publicKeys = [ main-user laptop-host ];
```

```sh
export RULES=security/secrets.nix
```

## Secret Usage

We are now ready to start using the secrets in our NixOS configuration.
Assuming the `agenix` module is correctly set up, we can split again in 2 parts:

1. Define the secret in your config via `age.secrets` option.
2. Use the secret via the `config.age.secrets` option.

Let's see how to define and use `api_token` on a host.

We start by telling the configuration where to find the `.age` file

```nix
# ./hosts/my-vm/configuration.nix
{ ... }:
{
  # Register Secrets
  age.secrets.api_token = {
    file = ../../api_token.age;
  };
}
```

You can also include `owner` and `group` which default to the user decrypting the files, and the `mode`.

And finally, to use the secret, and assuming the nix option expects a path to the secret location:

```nix
# ./hosts/my-vm/configuration.nix
{ config }:
{
  # ...
  example-reverse-proxy.api_token = config.age.secrets.api_token.path;
}
```

And that's all.

After a rebuild, **it should just work**.

And in this case, to rebuild the remote VM running NixOS, from our laptop, we use:

```sh
sudo nixos-rebuild switch --target-host root@[i:p:v:6] --flake ".#my-vm"
```

## Attack Vectors

I would say [agenix] is secure by design, because it relies on `age`, an established and well trusted library.
And secrets **do not end up in the nix store**, which is the downside of plaintext secrets.

The main concern would be the [Harvest now, decrypt later](https://en.wikipedia.org/wiki/Harvest_now,_decrypt_later) strategy.
Which can be mitigated by rotating secrets often and using Post-Quantum Cryptography (PQC), which is supported by `age` (with plugins as of today).

## Conclusion and Expectations

I've successfully onboarded [agenix] into my [nix-config].
It's okay, but to be honest, I'm a bit disappointed with its interface.
The secrets are repeated in the `secrets.nix` and then in the `age.secrets`.
I would rather define them once instead of having a `secrets.nix` plus the `age.secrets` module.

I recently found [vaultix], which seems like a more promising alternative.
Apparently, it natively adopts the strategy I described above.
And by natively, I mean that you only need to set a main key,
and it automatically picks the SSH keys from the hosts, in a signle place.
I would love to hear a confirmation of my understanding.

I hope you enjoyed the read!
