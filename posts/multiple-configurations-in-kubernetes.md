<!--
.. title: Multiple configurations in kubernetes
.. slug: multiple-configurations-in-kubernetes
.. date: 2019-11-08 15:15:28 UTC-03:00
.. tags: kubernetes, linux, configuration, kubectl
.. category: kubernetes
.. link:
.. description: How to manage multiple configuration files
.. type: text
-->

It may happen that you start working with 2 or more different clusters in
kubernetes. At this point, you'll want to have multiple config files, instead of
replacing `~/.kube/config`, which is fine the first few times.

In order to do this we only need to set `KUBECONFIG` env variable with the path to the kubeconfigs.

In kubernetes documentation is mentioned the creation of a `config-exercise` folder,
where the config files should live. So let's create it.

```bash
mkdir -p ~/.kube/config-exercise
```

The next thing is to add the env variable to our `.bashrc`, `.zshrc` or `.profile` file,
with the location of our configurations. The paths should be separated by a `:`.

```bash
export KUBECONFIG=$HOME/.kube/config-exercise/gke-config:$HOME/.kube/config-exercise/rbpi-config:$HOME/.kube/config-exercise/eks-config
```

Now reloading our terminal with `. ~/.bashrc`, or opening a new one should pick up the changes.

### Automating the config detection

Why not automate this? So everytime we add a new kubeconfig, it's detected automatically.

Here's my attempt, place this in your `.bashrc` or your other terminal file.

```bash
set_kubeconfig() {
    for entry in "$HOME/.kube/config-exercise"/*
    do
        # Get files which do not include "skip"
        if [ -f "$entry" ] && [[ $entry != *"skip"* ]];then
            kubeconfigs="$kubeconfigs:$entry"
        fi
    done

    # Clean first colons
    kubeconfigs=${kubeconfigs#":"}
    export KUBECONFIG=$kubeconfigs
}

set_kubeconfig
```

This script will get all the **files** inside `~/.kube/config-exercise`,
which do not include `skip` in their name, and will set the `KUBECONFIG`
variable to the found files.

Thanks for reading!
