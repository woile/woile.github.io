.. title: Tutorial: writing my dreamt cli using decli
.. slug: creating-a-small-git-like-cli-with-decli
.. date: 2018-09-14 14:33:02 UTC-03:00
.. tags: git python decli cli tutorial programming
.. category: python
.. link:
.. description: tutorial to write a command line interface with python decli
.. type: text

So for a long time I've been using different cli tools, mostly :code:`argparse` because this way I had zero dependencies, less worries.

Other tools such as click or docopt, the way the code must be written, is not something I'm really fond of.

Because of this, I created `decli <https://github.com/Woile/decli>`__, which is a declarative command line utility. Super simple.
Which is basically a wrapper around argparse.
Just write a dict and you are ready to go.

In this tutorial we are gonna try to simulate a *git command line tool*.
Let's create a few commands which will just print a message.

But we are gonna structure the code, the way I always wanted to hehe.

The commands will be decoupled from the *command line interface* (cli from now on).

These are the git commands we are gonna cover:

::

    add
    commit
    push

Our file structure will result in something like this:

::

    git-demo
    ├── git
    │   ├── commands
    │   │   ├── __init__.py
    │   │   ├── add.py
    │   │   ├── commit.py
    │   │   └── push.py
    │   ├── __init__.py
    │   └── __main__.py
    └── pyproject.toml

If you are gonna write code along with the tutorial, you can create those files already. You can skip the **pyproject.toml**.

The code for this tutorial is `hosted in github <https://github.com/Woile/decli-git-demo>`_.

Installation
------------

.. warning::

    Python3! Everything here is python3!

I like the new package manager :code:`poetry` which uses the new **pyproject.toml** file. So let's install:

::

    poetry add decli

Otherwise if you want to use pip:

::

    python -m venv venv
    source venv/bin/activate
    pip install -U decli

The pyproject.toml file
~~~~~~~~~~~~~~~~~~~~~~~

If you haven't seen how a **pyproject.toml** looks, it's something like this:

::

    [tool.poetry]
    name = "decli-git-demo"
    version = "0.1.0"
    description = "A git like demo"

    [tool.poetry.dependencies]
    python = "*"
    decli = "^0.5.0"

    [tool.poetry.dev-dependencies]
    pytest = "^3.0"
    flake8 = "^3.5"
    mypy = "^0.620.0"

Pretty simple, right?

Writing the interface
---------------------

We are gonna write the **cli** in the :code:`___main__.py` file, so we can treat the folder :code:`git` as a module.
Look at the file structure if in doubt.

In order to use it as a module, we need to provide the :code:`-m` flag, to the python interpreter.
Our resulting command would look something like this:

:code:`python -m git <top_level_arguments> <subcommand> <sub_arguments>`.

Example:

::

    python -m git --debug commit --amend

For the interface, using **decli**, we need to create a dict. Let's dive into it.

Main component
~~~~~~~~~~~~~~

.. code-block:: python

    from decli import cli

    data = {
        "prog": "git",
        "description": "These are common Git commands used in various situations"
    }

    parser = cli(data)
    args = parser.parse_args()

This part is the entrypoint of our cli.

The :code:`prog` key is the name of the app, it will be used in the help information, same as :code:`description`.
Let's see how this works:

::

    $ python -m git --help
    usage: git [-h]

    These are common Git commands used in various situations

    optional arguments:
    -h, --help  show this help message and exit

Arguments
~~~~~~~~~

Let's add some global arguments, we want to have :code:`debug` and :code:`version` available.
We are also going to add some code to handle the version flag.
And for now, if nothing is provided we'll print the args.

.. code-block:: python

    import sys
    from decli import cli

    data = {
        "prog": "git",
        "description": "These are common Git commands used in various situations",
        "arguments": [
            {"name": ["-v", "--version"], "action": "store_true"},
            {"name": "--debug", "action": "store_true"},
        ],
    }

    parser = cli(data)
    args = parser.parse_args()

    if args.version:
        print("0.1.0")
        sys.exit(0)

    print(args)

Let's take a look at the help, also to what happens when calling with the :code:`version` flag, and when nothing is provided.

::

    $ python -m git --help
    usage: git [-h] [-v] [--debug]

    These are common Git commands used in various situations

    optional arguments:
    -h, --help     show this help message and exit
    -v, --version
    --debug

::

    $ python -m git --version
    0.1.0

::

    $ python -m git
    Namespace(debug=False, version=False)

Awesome, this is looking promising.

Subcommands
~~~~~~~~~~~

Last thing we are missing are the subcommands, we said we were gonna cover :code:`add`, :code:`commit`, and :code:`push`.
Each one will have a unique sub-argument (just as an example).
Also, each one will use a class that we are gonna implement later. So no output example for now.

Some extras:

- We are gonna print the help if nothing is provided
- We are gonna call a :code:`run` method from the class that we are gonna define next


.. code-block:: python

    import sys
    from decli import cli
    from .commands import Add, Commit, Push

    data = {
        "prog": "git",
        "description": "These are common Git commands used in various situations",
        "arguments": [
            {"name": ["-v", "--version"], "action": "store_true"},
            {"name": "--debug", "action": "store_true"},
        ],
        "subcommands": {
            "title": "main",
            "commands": [
                {
                    "name": "add",
                    "help": "Add file contents to the index",
                    "func": Add,
                    "arguments": [{"name": "--update", "action": "store_true"}],
                },
                {
                    "name": "commit",
                    "help": "Record changes to the repository",
                    "func": Commit,
                    "arguments": [
                        {
                            "name": "--amend",
                            "action": "store_true",
                            "help": (
                                "Replace the tip of the current "
                                "branch by creating a new commit."
                            ),
                        }
                    ],
                },
                {
                    "name": "push",
                    "help": "Update remote refs along with associated objects",
                    "func": Push,
                    "arguments": [
                        {
                            "name": "--tags",
                            "action": "store_true",
                            "help": (
                                "All refs under refs/tags are pushed, in"
                                " addition to refspecs explicitly listed "
                                "on the command line."
                            ),
                        }
                    ],
                },
            ],
        },
    }

    parser = cli(data)
    args = parser.parse_args()

    if args.version:
        print("0.1.0")
        sys.exit(0)

    # print help if no arguments are provided
    if len(sys.argv) < 2:
        parser.print_help()
        sys.exit()

    cmd = args.func(**args.__dict__)
    cmd.run()

So this is how :code:`___main__.py` should look like.


Writing the commands
--------------------

So before, we left our application unfinished and not working, because it was missing the classes imported from the :code:`commands` folder.
If you haven't created the folder and the files yet, go and do it. Remember also to create the :code:`___init__.py` files.

It's interesting to observe how each class is unpacking the arguments that needs.

Also, each class is a normal python class, there's nothing needed, really **easy to test**.

A better implementation could be made, of course, having a parent class defining the interface and handling global arguments, would be interesting.

Add
~~~

For :code:`commands/app.py`

.. code-block:: python

    class Add:

        def __init__(self, debug=False, update=False, **kwargs):
            self.debug = debug
            self.update = update

        def run(self):
            print(f'running add... update: {self.update}, debug: {self.debug}')

Commit
~~~~~~

For :code:`commands/commit.py`

.. code-block:: python

    class Commit:

        def __init__(self, debug=False, amend=False, **kwargs):
            self.debug = debug
            self.amend = amend

        def run(self):
            print(f'Commiting... debug: {self.debug}, amend: {self.amend}')

Push
~~~~

For :code:`commands/push.py`

.. code-block:: python

    class Push:

        def __init__(self, debug=False, tags=False, **kwargs):
            self.debug = debug
            self.tags = tags

        def run(self):
            print(f'Pushing... debug: {self.debug}, tags: {self.tags}')

Init
~~~~

For :code:`commands/__init__.py`

.. code-block:: python

    from .add import Add
    from .commit import Commit
    from .push import Push

    __all__ = (
        'Add',
        'Commit',
        'Push'
    )

Now what?
---------

That's it, our application is completed, let's see some output results.

Providing nothing
~~~~~~~~~~~~~~~~~

::

    $ python -m git
    usage: git [-h] [-v] [--debug] {add,commit,push} ...

    These are common Git commands used in various situations

    optional arguments:
    -h, --help         show this help message and exit
    -v, --version
    --debug

    main:
    {add,commit,push}
        add              Add file contents to the index
        commit           Record changes to the repository
        push             Update remote refs along with associated objects

Calling add commnand
~~~~~~~~~~~~~~~~~~~~

::

    $ python -m git add
    running add... update: False, debug: False

Calling commit commnand with a sub-argument
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

::

    $ python -m git commit --amend
    Commiting... debug: False, amend: True

Calling push commnand with global and a sub arguments
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

::

    $ python -m git --debug push --tags
    Pushing... debug: True, tags: True


Help for one of the commands
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

::

    $ python -m git add --help
    usage: git add [-h] [--update]

    optional arguments:
    -h, --help  show this help message and exit
    --update


And that's it, we have succesfully created a nice and mantainable cli.

Also if you already have a project and you want to provide an interface, now you know how.

Hope it was a useful reading.
