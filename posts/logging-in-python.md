<!--
.. title: Logging in python
.. slug: logging-in-python
.. date: 2022-05-11 13:21:55 UTC
.. tags: python, logging
.. category: python
.. link:
.. description: Easy and simple logging setup for a new python project. Are you tired of searching how to do it and why it doesn't work? this is your place
.. type: text
-->

For future reference, this is my logging configuration for a new project.

It is not intended for libraries which already have some kind of set up in place, like django.

## Simple logging configuration

This is a good configuration to start logging right away.
You can use it when you have a single file, or you can share the `logger` if stored in a separated file,
which is not recommended when you start growing.

```python
import logging
import os
import sys

LOGLEVEL = os.environ.get('LOGLEVEL', 'INFO').upper()
logger = logging.getLogger("my_app")
logger.setLevel(LOGLEVEL)
console_handler = logging.StreamHandler(sys.stdout)
formatter = logging.Formatter("[%(asctime)s] %(name)s:%(lineno)d %(levelname)s :: %(message)s")
console_handler.setFormatter(formatter)
console_handler.setLevel(LOGLEVEL)
logger.addHandler(console_handler)

# Send messages
logger.debug("Set LOGLEVEL=DEBUG to see this")
logger.info("An info log")
```

You can also replace `name` with `pathname` to get the full path.

## Project-wide logging configuration

In this case we want to configure the logs once, by using the popular dict logging conf:

```python
# ./my_app/logs.py
LOGGING_CONFIG = {
    "version": 1,
    "disable_existing_loggers": True,
    "formatters": {
        "standard": {
            "format": "[%(asctime)s] %(name)s:%(lineno)d %(levelname)s :: %(message)s"
        },
    },
    "handlers": {
        "default": {
            "level": "INFO",
            "formatter": "standard",
            "class": "logging.StreamHandler",
            "stream": "ext://sys.stdout",  # Default is stderr
        },
    },
    "loggers": {
        "": {  # root logger
            "handlers": ["default"],
            "level": "WARNING",
            "propagate": False,
        },
        "__main__": {  # if __name__ == '__main__'
            "handlers": ["default"],
            "level": "DEBUG",
            "propagate": False,
        },
        "my_app": {  # folder
	        "handlers": ["default"],
	        "level": "INFO",
	        "propagate": False
	    },
    },
}

import logging.config

def init():
    # Run once at startup:
    logging.config.dictConfig(LOGGING_CONFIG)
```

```python
# ./my_app/foo.py
import logs

logs.init()
logger = logging.getLogger(__name__)

# Send messages
logger.debug("Set LOGLEVEL=DEBUG to see this")
logger.info("Hello world")
```

And your folder structure should look something like:

```sh
my-app/
└── my_app/
    ├── foo.py
    └── logs.py
```


## Structured logging

Structured logs are usually in JSON format, making it easy for machines to parse and index them. See for example [structured logging with filebeat](https://www.elastic.co/blog/structured-logging-filebeat).
A common format is bunyan, based on [bunyan-node](https://github.com/trentm/node-bunyan).

```
pip install bunyan
```

```python
import logging
import bunyan
import sys

logger = logging.getLogger("my_app")
logger.setLevel(logging.INFO)
console_handler = logging.StreamHandler(sys.stdout)
formatter = bunyan.BunyanFormatter()
console_handler.setFormatter(formatter)
console_handler.setLevel(logging.INFO)
logger.addHandler(console_handler)

# Send messages
logger.debug("Set LOGLEVEL=DEBUG to see this")
logger.info("Hello world")
```

The output of this script would only show the `info` logger, and it would look like this:

```json
{"name": "my_app", "msg": "Hello world", "time": "2022-06-21T07:41:06Z", "hostname": "<REDACTED>", "level": 30, "pid": 40625, "v": 0}
```

For local development, pipe the logs to the buyan cli, so they become friendly for developers.

```sh
wget -c https://github.com/LukeMathWalker/bunyan/releases/download/v0.1.7/bunyan-v0.1.7-x86_64-unknown-linux-gnu.tar.gz -O - | tar -xz

python my_app.py | ./bunyan
```

## Docker issues

Sometimes the logs are not sent to the terminal right away, specially if something is blocking. To prevent this, send right away the output to the terminal by setting the env `PYTHONUNBUFFERED=1`.

### Dockerfile

Include this line

```dockerfile
ENV PYTHONUNBUFFERED 1
```

## Running docker

```sh
docker run --env "PYTHONUNBUFFERED=1" python:slim bash
```

## Docker-compose

```yaml
version: '3'
services:
  my_app:
    # ...
    environment:
      - PYTHONUNBUFFERED=1
```