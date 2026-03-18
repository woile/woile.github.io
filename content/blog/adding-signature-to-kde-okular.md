+++
title = "Adding signature to KDE Okular"
description = "A step-by-step guide to creating digital signatures and configuring Okular to sign PDF documents on Linux systems, particularly NixOS."
date = 2025-04-23
section_type = "blog"
tags = ["KDE", "linux", "PDF", "signature", "esignature", "nixos", "security"]
aliases = ["/blog/adding-signature-to-kde-okular"]
+++

I've been using [Okular](https://okular.kde.org/) to open and annotate PDFs on NixOS.
It's an excellent piece of software. But I had trouble adding signatures to PDFs.

I was confused by the instructions. Turns out you have to do the following:

1. Create a digital signature certificate
2. Import the certificate into [nss](https://firefox-source-docs.mozilla.org/security/nss/index.html) (through Firefox)
3. Configure Okular backend
4. Sign documents

In order to create a digital signature, we can use the following script:

```sh
#! /usr/bin/env nix-shell
#! nix-shell openssl
export USER_ID=woile
export FULL_NAME="Your Full Name"

mkdir ~/.signatures
cd ~/.signatures
openssl genrsa -out "$USER_ID.priv.key" 2048

# Here you'll get a bunch of questions, remember to use '.' if you want an empty field
openssl req -new -key "$USER_ID.priv.key" -out "$USER_ID.csr"

openssl x509 -req -days 365 -in "$USER_ID.csr" -signkey "$USER_ID.priv.key" -out "$USER_ID.certificate.crt"
openssl pkcs12 -export -out "$USER_ID.sign.p12" -inkey "$USER_ID.priv.key" -in "$USER_ID.certificate.crt" -name "$FULL_NAME"
```

The end result will be a file named `woile.sign.p12` in the `~/.signatures` directory.

Then we load the `p12` certificate file into Firefox:

Firefox >> Settings >> Privacy and Security >> View Certificates >> Your Certificates (1st tab)

And finally we go to Okular >> Settings >> Configure Backends

You may have to change the "Certificate Database", mine for example is created by NixOS as `~/.mozilla/firefox/9q8doo6z.Santiago`

It would be nice if provisioning certificates could be done through NixOS, but I'm still not sure how to do it.

I hope you enjoyed this article and let me know your thoughts in mastodon:

[@woile](https://hachyderm.io/@woile)
