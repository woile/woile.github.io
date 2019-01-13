.. title: Local HTTPS development in Python with Mkcert
.. slug: local-https-development-in-python-with-mkcert
.. date: 2019-01-10 14:30:24 UTC-03:00
.. tags: web frameworks development security https
.. category: python
.. link:
.. description: setting https in our local development servers with python and mkcert
.. type: text

.. contents::
    :local:
    :depth: 2

About mkcert
------------

`mkcert <https://github.com/FiloSottile/mkcert/>`_ allows you to have a local
certificate authority (CA).
This means that you can run your development web server using HTTPS.
You'll see the green lock in your browser.

.. raw:: html

    <img src="/images/local-https-development-in-python-with-mkcert/https.png">

You might not need it most of the time, but more and more features require
HTTPS by default in the browser, like web bluetooth, service workers, web authentication
and websockets in some cases where SSL is already enabled.

Configuring mkcert
------------------

Install the `dependencies for your os <https://github.com/FiloSottile/mkcert/#installation>`_.
In my case I'm using a Linux Debian based os.

.. code-block:: console

    sudo apt install libnss3-tools

Download the binary for your distribution from
`mkcert release page <https://github.com/FiloSottile/mkcert/releases>`_

Rename the file to :code:`mkcert` and give execution permissions

.. code-block:: console

    chmod +x mkcert

Install the certificate authorities (CA) using

.. code-block:: console

    ./mkcert -install

Create certificates for the domains you'd like to use

.. code-block:: console

    ./mkcert -cert-file cert.pem -key-file key.pem 0.0.0.0 localhost 127.0.0.1 ::1

This will create a :code:`cert.pem` and a :code:`key.pem` files in your current directory.
We are gonna use this 2 files along the post.

Python frameworks
-----------------

Now that we have created the certficates for those domains, we just need to
know how to tell our app to use them.

I'll assume you have a virtualenv already created.

Let's see how to do this in some different python frameworks and tools.

Uvicorn + Starlette
~~~~~~~~~~~~~~~~~~~~

Note: `uvicorn <https://github.com/encode/uvicorn>`_ SSL Support has not been merged yet.
I've tested this with this open `PR <https://github.com/encode/uvicorn/pull/213>`_.

I've used `starlette <https://github.com/encode/starlette>`_
because it's simpler than writing a uvicorn App, but it's not required.

I guess this should be fairly similar for `FastAPI <https://github.com/tiangolo/fastapi>`_,
`Bocadillo <https://github.com/bocadilloproject/bocadillo>`_ and `Responder <https://github.com/kennethreitz/responder>`_
once the PR gets merged into uvicorn.

In your terminal run

.. code-block:: console

    pip install uvicorn starlette


Now create a file :code:`star_app.py`

.. code-block:: python

    # star_app.py
    from starlette.applications import Starlette
    from starlette.responses import JSONResponse
    import uvicorn
    import ssl

    app = Starlette()


    @app.route("/")
    async def homepage(request):
        return JSONResponse({"hello": "world"})

    if __name__ == "__main__":
        uvicorn.run(
            app,
            host="0.0.0.0",
            port=8433,
            ssl_version=ssl.PROTOCOL_SSLv23,
            cert_reqs=ssl.CERT_OPTIONAL,
            keyfile="./key.pem",        # Note that the generated certificates
            certfile="./cert.pem",      # are used here
        )

And then just run

.. code-block:: console

    python star_app.py


Go to :code:`https://0.0.0.0:8443` in your browser

Django SSL Server
~~~~~~~~~~~~~~~~~

`django-sslserver <https://github.com/teddziuba/django-sslserver>`_ is a small library which adds the ability to
run a secure debug server with the certificates we just created.

.. code-block:: console

    pip install django-sslserver


Update your :code:`settings.py`

.. code-block:: python

    INSTALLED_APPS = (...
        'sslserver',
        ...
    )

And in your terminal run

.. code-block:: console

    python manage.py runsslserver --certificate cert.pem --key key.pem


Django extensions
*****************

There's another alternative which I haven't tested, but it has a lot of extra functionality,
which I don't need, so I've skipped it.

Feel free to try `django-extensions <https://django-extensions.readthedocs.io/en/latest/runserver_plus.html>`_

I guess it would be something like

.. code-block:: console

    python manage.py runserver_plus --cert-file cert.pem --key-file cert.pem


Flask
~~~~~

Install `flask <http://flask.pocoo.org/>`_

.. code-block:: console

    pip install flask


Create a file :code:`flask_app.py`

.. code-block:: python

    # flask_app.py
    from flask import Flask

    application = Flask(__name__)

    @application.route("/")
    def hello():
        return "<h1 style='color:blue'>Hello There!</h1>"

    if __name__ == "__main__":
        application.run(ssl_context=('cert.pem', 'key.pem'))


Run in your terminal

.. code-block:: console

    python flask_app.py


UWSGI
~~~~~

Install `uwsgi <https://uwsgi-docs.readthedocs.io>`_.

.. code-block:: console

    pip install uwsgi

Create a file called :code:`wsgi.py`

.. code-block:: python

    # wsgi.py
    def application(env, start_response):
        start_response('200 OK', [('Content-Type', 'text/html')])
        return [b"Hello World"]

Run in your terminal

.. code-block:: console

    uwsgi -w wsgi --https=0.0.0.0:8443,cert.pem,key.pem


Go to :code:`https://0.0.0.0:8443`

Security concerns
-----------------

**DO NOT** use this certificates in production. This is **only** for development. Use `Let's Encrypt <https://letsencrypt.org/>`_ instead.

You don't need to commit the generated certificates.
Looks like each machine will have to install mkcert, create and work with its own certificates.

This will only work on your local machine, where the server is running, if you want to access from a mobile device
read `the docs <https://github.com/FiloSottile/mkcert#mobile-devices>`_.

Conclusion
----------

Many times, I've had the need to test something with HTTPS, but it took me a lot of time to do it.
I think :code:`mkcert` is a really easy to use tool which achieves this smoothly.

Do you have any other (security) concerns? Feedback is appreciated.

If you have drop-in examples for other frameworks or tools I'll update the post.

Thanks for reading and happy coding!
