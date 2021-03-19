<!--
.. title: Pyenv
.. slug: pyenv
.. date: 2020-07-08 09:07:26 UTC
.. tags: python, python-versions, tutorial
.. category: python
.. link:
.. description: How to configure pyenv in your system
.. type: text
-->

## Description

[pyenv][pyenv] is a shell script to manage python versions.
Works in the user space, avoiding the system's python, therefore is less error prone.
You can also control a per directory version (this creates a `.python-version`).
Doesn't require python.

## Installation

Use [pyenv-installer][pyenv-installer]

```bash
curl https://pyenv.run | bash
exec $SHELL  # Restart shell or open new terminal
```

## Usage

### Install different python versions

```bash
pyenv install 3.6.10
pyenv install 3.7.6
```

### Set global python

```bash
pyenv global 3.7.6
```

Observe

```bash
python --version
type -a python
```

### Set local python

```bash
cd ~/my-project
pyenv local 3.6.10
```

Observe

```bash
cat .python-version
python --version
type -a python
```

### Other languages

There's a set of similar tools for other languages, following the
same convention here, so if you know `pyenv`, you know `nodenv` for example.

- **ruby:** [rbenv][rvenv]
- **javascript:** [nodenv][nodenv]
- **go:** [goenv][goenv]
- **php:** [phpenv][phpenv]

### More resources

- [In depth tutorial by real python][realpython]
- [Official docs][pyenv]

> Hey, hello 👋
>
> If you are interested in what I write, follow me on [twitter][santiwilly]
>

[santiwilly]: https://twitter.com/santiwilly
[pyenv]: https://github.com/pyenv/pyenv
[rvenv]: https://github.com/rbenv/rbenv
[nodenv]: https://github.com/nodenv/nodenv
[pyenv-installer]: https://github.com/pyenv/pyenv-installer
[goenv]: https://github.com/syndbg/goenv
[phpenv]: https://github.com/phpenv/phpenv
[realpython]: https://realpython.com/intro-to-pyenv/
