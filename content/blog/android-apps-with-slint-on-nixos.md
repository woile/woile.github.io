+++
title = "Android apps with Slint on NixOS"
description = "A step-by-step guide to setting up an Android development environment on NixOS using Slint UI library and Rust. Learn how to configure Nix flakes, handle Android SDK integration, and run applications in an emulator with reproducible builds"
date = 2025-04-13
tags = ["rust", "android", "gui"]
aliases = ["/blog/android-apps-with-slint-nixos"]
+++

Before moving to the south of Holland, and later starting traveling with my girlfriend,
we were using a blackboard to keep track of the days we hadn't eaten added sugars.
I was inspired by [Simon Willision's blog](https://simonwillison.net/2024/Jan/2/escalating-streaks/) about the power of streaks. Thus I created some mechanics for this streaks game, and we started "playing" it at home.
It was a success, one of our streaks even lasted 45 days without added sugar (with some caveats).
I've always wanted to transform the experience into an app, so we wouldn't depend on the location we were in.

Now, while traveling, I've been setting up the environment to run the android app. As it was such a struggle, because I know little to nothing of android development, I decided to document the journey.

**The goal of this blog is to set up a nix flake, in order to run an android app built with slint.**


## Slint

[Slint](https://slint.dev) is a rust UI library. Might not be the most popular right now, but unlike other UI libraries,
slint has its own UI language to describe the layout. Making it akin to Qt's QML. I'm not entirely sure if it's the best
approach (that says more about my ignorance than the approach). However, it's a proven approach, as there's a plethora of
Qt applications out there, which run quite smoothly, like KDE, Ableton Live, Krita, OBS and more. Therefore, I'm quite
happy there's an alternative to QML in rust.

Separating layout from code also makes it easier for designers to work on the UI without needing to know rust,
and the slint team has even built a live preview, and a plugin for Figma.
I saw [Tobias's talk in RustLab 2024](https://www.youtube.com/watch?v=6mfzlaBSZUw) and I was quite blown away by its capabilities.

This is how the slint code looks like:

```
component MemoryTile inherits Rectangle {
    width: 64px;
    height: 64px;
    background: #3960D5;

    Image {
        source: @image-url("icons/bus.png");
        width: parent.width;
        height: parent.height;
    }
}

export component MainWindow inherits Window {
    MemoryTile {}
}
```

## Prerequisites

- [NixOS](https://nixos.org/download/#nixos-iso) (or [nix](https://nixos.org/download/#nix-install-linux) installed)

## Initial flake

Let's start by creating a folder and using my template for a rust development shell:

```sh
mkdir android-app
cd android-app
nix flake init -t github:woile/nix-config#rust-shell
git init && git add -N .  # promise to add the files later, so we get a hash for the flake
```

At the time of writing, we'll get a `flake.nix` and a `.envrc`,
with a `flake.nix` that looks like this (I've added the `self` because we are gonna use it later):

```nix
{
  description = "A development shell for rust";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs@{
      flake-parts,
      self,
      ...
    }:
    # https://flake.parts/
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        { pkgs, inputs', ... }:
        {
          devShells.default = pkgs.mkShell {
            name = "dev";

            # Available packages on https://search.nixos.org/packages
            buildInputs = with pkgs; [
              just
              inputs'.fenix.packages.stable.toolchain
            ];

            shellHook = ''
              echo "Welcome to the rust devshell!"
            '';
          };
        };
    };
}
```

If we have [direnv](https://direnv.net/) installed and configured, we can just run `direnv allow` and we'll have the shell setup and configured for us, as soon as we jump into the folder in our terminals.

Otherwise, you'll have to run `nix develop` to get into the shell.

## Exploring the nix flake

If we start looking at the `flake.nix`, we'll notice that it has 2 inputs:

- `nixpkgs` which is the nixpkgs flake, where all the packages come from
- `fenix` which provides an **up-to-date** rust toolchain, and with it, we can set up everything we need for rust development.

Next, the `outputs` are created using [flake-parts](https://flake.parts/). Which makes it easy to create per-system configurations that run on most popular platforms.

```nix
systems = [
  "x86_64-linux"
  "aarch64-darwin"
  "x86_64-darwin"
];
perSystem =
  { pkgs, inputs', ... }:
  {
    ...
  };
```

Inside the `perSystem` function, we have a `devShells.default` that sets up a shell with the `just` package and the `fenix` toolchain.

## Create the rust project

Once we jump into the shell, the rust toolchain should be available and we can create a rust project and start adding the dependencies for slint:

```sh
cargo init --lib .
cargo add slint -F backend-android-activity-06
```

In the `lib.rs` let's add all the slint code we are using in this blog.
We are embedding the `*.slint` file directly into the rust code, for simplicity.

```rs
#[unsafe(no_mangle)]
fn android_main(app: slint::android::AndroidApp) {
    slint::android::init(app).unwrap();

    slint::slint! {
        export component MainWindow inherits Window {
            Text { text: "Hello World"; }
        }
    }
    MainWindow::new().unwrap().run().unwrap();
}
```

## Configuring the rust project

Next, we'll take a look at the the [slint documentation for android](https://docs.slint.dev/latest/docs/rust/slint/android/).

First thing I've noticed, is that we need to update the `Cargo.toml` to include the lib configuration:

```toml
[lib]
crate-type = ["cdylib"]
```

And it mentions that we need to add a new target: `aarch64-linux-android`

This was a problem for me when setting up android, as I'm on a linux with `x86_64`, and I didn't know the emulator *should* run on your host arch.

Therefore, we are going to add 2 target architectures:

- `aarch64-linux-android`: in case you want to run the app on your phone
- `x86_64-linux-android`: in case you want to run the app on an emulator

We need to update the flake to reflect this, our `devShells.default.buildInput`
will now look like this:

```diff
buildInputs = with pkgs; [
  just
-  inputs'.fenix.packages.stable.toolchain
+  (
+    with inputs'.fenix.packages;
+    combine [
+      stable.toolchain
+      targets.aarch64-linux-android.stable.rust-std
+      targets.x86_64-linux-android.stable.rust-std
+    ]
+  )
];
```

Plus, `cargo-apk` as recommended in the slint docs:

```diff
buildInputs = with pkgs; [
  just
  (
    with inputs'.fenix.packages;
    combine [
      stable.toolchain
      targets.aarch64-linux-android.stable.rust-std
      targets.x86_64-linux-android.stable.rust-std
    ]
  )
+ cargo-apk
];
```

Let's keep track of the command we are going to run in the `justfile`:

```sh
touch justfile
```

```make
# Run the android app
run-android:
    cargo apk run --target x86_64-linux-android --lib
```

Notice that we are using the host's architecture to build the apk, because we are going to run the emulator with that arch. If you are running on a different architecture, like for example, if you are actually running against your device, you should change the `--target` flag to match your host's architecture.

## Android setup

To run the android app, we'll have to configure a bunch of things.
Knowing little to nothing about android development, and looking at the [slint docs](https://docs.slint.dev/latest/docs/rust/slint/android/),
we know that in order to run an android app we need the following env variables:

- `ANDROID_HOME`
- `ANDROID_NDK_ROOT`
- `JAVA_HOME`

The way I see it, if we have those variable set right, slint should be able to build an `apk` and install it on the android device.

The last one: `JAVA_HOME` should be the easiest to set up, we add the dependency
to the `buildInputs` of the `devShells.default`. Which will automatically add
the env variable.

```diff
buildInputs = with pkgs; [
  just
  (
    with inputs'.fenix.packages;
    combine [
      stable.toolchain
      targets.aarch64-linux-android.stable.rust-std
      targets.x86_64-linux-android.stable.rust-std
    ]
  )
  cargo-apk
+  jdk
];
```

For the other 2 variables, we read what nix has to say about android:

- [Nix Android wiki](https://wiki.nixos.org/wiki/Android)
- [Nixpks android language framework](https://nixos.org/manual/nixpkgs/stable/#android)
- [Android SDK](https://developer.android.com/studio/command-line/sdkmanager)

It took me a while to figure out exactly what I needed, I don't know if it's a
docs problem, or my utter ignorance about android development, probably a bit of both.
But we cannot use `android-studio-full`.
Instead we are gonna have to refactor the flake quite a bit, by initializing a bunch of variables:


```diff
      perSystem =
        {
          pkgs,
          inputs',
+          lib,
+          system,
          ...
        }:
+        let
+          platformVersion = "35";
+          systemImageType = "default";
+          currentPath = builtins.getEnv "PWD";
+          androidEnv = pkgs.androidenv.override { licenseAccepted = true; };
+          androidComp = (
+            androidEnv.composeAndroidPackages {
+              cmdLineToolsVersion = "8.0";
+              includeNDK = true;
+              # we need some platforms
+              platformVersions = [
+                "30"
+                platformVersion
+              ];
+              # we need an emulator
+              includeEmulator = true;
+              includeSystemImages = true;
+              systemImageTypes = [
+                systemImageType
+                # "google_apis"
+              ];
+              abiVersions = [
+                "x86"
+                "x86_64"
+                "armeabi-v7a"
+                "arm64-v8a"
+              ];
+              cmakeVersions = [ "3.10.2" ];
+            }
+          );
+          android-sdk = (pkgs.android-studio.withSdk androidComp.androidsdk);
+        in
        {
         # accept android license (id-2)
+         _module.args.pkgs = import self.inputs.nixpkgs {
+           inherit system;
+           config.allowUnfree = true;
+           config.android_sdk.accept_license = true;
+           config.allowUnfreePredicate =
+             pkg:
+             builtins.elem (lib.getName pkg) [
+               "terraform"
+             ];
+         };
          # same as we previously saw (id-1)
          devShells.default = {
            ...
          };
          ...
        }
```
These variables will not only be used to initialize the android environment,
but also to configure the android emulator, system images and environment variables for the android development tools.
They all kind of have to match the android environment.

That's why we set `platformVersion` to "35" which refers to the API for "Vanilla Ice Cream", which is android 15.
Most of the other variables are set based on the nix docs about android.

We also accept android license, by temporary modifying the nixpkgs configuration on the flake (`id-2`).

### Android emulator

We can either use our phone, or run an emulator.
We are choosing the second option, and for that, we'll use our system's architecture.

In nix terms, we are gonna add a package, and use nix to run it.

Let's see how it would look:

```nix
let
  ...
in {
  # continue from id-1
  packages.android-emulator = androidEnv.emulateApp {
    name = "emulate-MyAndroidApp";
    platformVersion = platformVersion;
    abiVersion = "x86_64"; # armeabi-v7a, mips, x86_64, arm64-v8a
    systemImageType = systemImageType;
  };
  # same as we previously saw (id-1)
  devShells.default = {
    ...
  };
  ...
}
```

Now with this package, we can update our `justfile` to build and run the emulator in a single command:

```diff
# Run the android app
run-android:
    cargo apk run --target x86_64-linux-android --lib

+ # Run the android emulator
+ run-emulator:
+     nix run .#android-emulator
```

Now we can run the emulator with the following command:

```bash
just run-emulator
```

## Trying the set up out

What happens if we run the android app?

```sh
just run-android
```

We get the following error:

```console
Error: Android SDK is not found. Please set the path to the Android SDK with the $ANDROID_SDK_ROOT environment variable.
error: Recipe `run-android` failed on line 2 with exit code 1
```

Hence, slint is smart enough to detect android's not fully configured.

## Configuring env variables

Part of the reason we set some variables with `let .. in ..` in the flake,
is to be able to set the android env variables in the devshell.

Let's finish that:

```diff
{
  devshell.default = {
    ...
+   ANDROID_HOME = "${androidComp.androidsdk}/libexec/android-sdk";
+   ANDROID_SDK_ROOT = "${androidComp.androidsdk}/libexec/android-sdk";
+   ANDROID_NDK_ROOT = "${androidComp.androidsdk}/libexec/android-sdk/ndk-bundle";
  };
}
```

Now with this variables in place, we can run the android app:

```sh
just run-android
```

We should see the emulator opening our android app with a "Hello World" message.

## Troubleshooting

There are 2 extra variables I've set that help things go smooth on linux:

```diff
{
  devshell.default = {
    ...
    ANDROID_HOME = "${androidComp.androidsdk}/libexec/android-sdk";
    ANDROID_SDK_ROOT = "${androidComp.androidsdk}/libexec/android-sdk";
    ANDROID_NDK_ROOT = "${androidComp.androidsdk}/libexec/android-sdk/ndk-bundle";

+    CARGO_HOME = "${currentPath}/.cargo-home";
+    LD_LIBRARY_PATH = "$LD_LIBRARY_PATH:${
+      with pkgs;
+      lib.makeLibraryPath [
+        wayland
+        libxkbcommon
+        fontconfig
+      ]
+    }";
  };
}
```

The first one, `CARGO_HOME` is for rust to not share the same directory with other rust installations.
The second one, `LD_LIBRARY_PATH` is for running the application on KDE.

## Final result

We get this beautiful `flake.nix`

```nix
{
  description = "A development shell for rust";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs@{
      flake-parts,
      self,
      ...
    }:
    # https://flake.parts/
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        {
          pkgs,
          inputs',
          lib,
          system,
          ...
        }:
        let
          platformVersion = "35";
          systemImageType = "default";
          currentPath = builtins.getEnv "PWD";
          androidEnv = pkgs.androidenv.override { licenseAccepted = true; };
          androidComp = (
            androidEnv.composeAndroidPackages {
              cmdLineToolsVersion = "8.0";
              includeNDK = true;
              # we need some platforms
              platformVersions = [
                "30"
                platformVersion
              ];
              # we need an emulator
              includeEmulator = true;
              includeSystemImages = true;
              systemImageTypes = [
                systemImageType
                # "google_apis"
              ];
              abiVersions = [
                "x86"
                "x86_64"
                "armeabi-v7a"
                "arm64-v8a"
              ];
              cmakeVersions = [ "3.10.2" ];
            }
          );
          android-sdk = (pkgs.android-studio.withSdk androidComp.androidsdk);
        in
        {
          _module.args.pkgs = import self.inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
            config.android_sdk.accept_license = true;
            config.allowUnfreePredicate =
              pkg:
              builtins.elem (lib.getName pkg) [
                "terraform"
              ];
          };
          packages.android-emulator = androidEnv.emulateApp {
            name = "emulate-MyAndroidApp";
            platformVersion = platformVersion;
            abiVersion = "x86_64"; # armeabi-v7a, mips, x86_64, arm64-v8a
            systemImageType = systemImageType;
          };
          devShells.default = pkgs.mkShell {
            name = "dev";

            # Available packages on https://search.nixos.org/packages
            buildInputs = with pkgs; [
              just
              (
                with inputs'.fenix.packages;
                combine [
                  stable.toolchain
                  targets.aarch64-linux-android.stable.rust-std
                  targets.x86_64-linux-android.stable.rust-std
                ]
              )
              cargo-apk
              jdk
              android-sdk
            ];

            shellHook = ''
              echo "Welcome to the rust devshell!"
            '';

            ANDROID_HOME = "${androidComp.androidsdk}/libexec/android-sdk";
            ANDROID_SDK_ROOT = "${androidComp.androidsdk}/libexec/android-sdk";
            ANDROID_NDK_ROOT = "${androidComp.androidsdk}/libexec/android-sdk/ndk-bundle";

            CARGO_HOME = "${currentPath}/.cargo-home";
            LD_LIBRARY_PATH = "$LD_LIBRARY_PATH:${
              with pkgs;
              lib.makeLibraryPath [
                wayland
                libxkbcommon
                fontconfig
              ]
            }";
          };
        };
    };
}
```

If you are running direnv a simple `direnv allow` should load everything into your
terminal, otherwise you'll have to run `nix develop`.

And our `justfile` would stay the same:

```make
# Run the android app
run-android:
    cargo apk run --target x86_64-linux-android --lib

# Run the android emulator
run-emulator:
    nix run .#android-emulator
```

## Conclusion

After a long struggle, I managed to set up NixOS for android applications with Slint.
It was tough!

Slint's documentation is relatively good, and NixOS's documentation could be better,
by explaining concepts more in depth. Why?
Because NixOS's users know they cannot **start** as everybody else.
For example, this case, if I'm starting with Android, I won't go to Android documentation first, but to NixOS documentation,
cause for sure it's going to be different than what Android docs say.

On the plus side, once you get things right, they just work, which is mind blowing, **and reproducible**!

I hope you enjoyed this article and let me know your thoughts in mastodon:

[@woile](https://hachyderm.io/@woile)
