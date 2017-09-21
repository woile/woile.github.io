.. title: How to test Selenium scrapper with Python
.. slug: how-to-test-selenium-scrapper
.. date: 2017-09-12 11:38:40 UTC-03:00
.. tags:
.. category:
.. link:
.. description:
.. type: text


This week I've been writing tests for `a project <https://github.com/discov-r/pyinstamation>`_ which is
using Selenium as a scrapper.

As you may know, Selenium is a testing framework, it's intended to be used while writing tests,
not as a web crawler/scrapper.

But you can. Why? Because it runs a browser, and the browser is the real sh*t, so the Javascript
gets executed, and we are happy. There are other solutions like `Spynner <https://github.com/makinacorpus/spynner>`_
or writing the scrapper in pure Javascript, but I felt comfortable using Selenium this way.

The problem
------------

How do we **test** this scrapper? I want it to have tests, damn!

Solution
-----------

Save the static content while running the scrapper, then, serve it with a very small http server
while testing. Yes, it's a bit tedious, but it delivers.

When should you save?

Whenever you need to. This is a good example:

.. code-block:: python

    url = 'https://betterexplained.com/articles/why-do-we-multiply-combinations/'
    driver = webdriver.Chrome()
    driver.get(url)
    save_current_state(driver.current_url, driver.page_source)

Can I see the code of :code:`save_current_state`? Here you go:

.. code-block:: python

    import os
    from urllib.parse import quote

    SAVE_SOURCE = True  # disable in production
    TEST_LOCATION = 'tests/static'


    def save_current_state(url, source, location=None):
        if not SAVE_SOURCE:
            return None
        if location is None:
            location = TEST_LOCATION
        if not isinstance(source, str):
            raise TypeError('source must be a string')

        filename = quote(url.strip('/') or '/', safe='') + '.html'
        filepath = os.url.join(location, filename)
        with open(filepath, 'w') as f:
            f.write(source)

        return filepath


Notice how the url is used as the file name (safely parsed). This helps a lot to match urls.
But of course, a case where something custom is required may happen, so you can tune the server to
fit any case.

And the python server? A minor modification from `here <https://realpython.com/blog/python/testing-third-party-apis-with-mock-servers/>`_

.. code-block:: python

    import os
    import socket
    from threading import Thread
    from urllib.parse import quote
    from http.server import BaseHTTPRequestHandler, HTTPServer


    TEST_LOCATION = 'tests/static'


    class MockServerRequestHandler(BaseHTTPRequestHandler):

        def _set_headers(self):
            self.send_response(200)
            self.send_header('Set-Cookie', 'exampleid=c295IGVsIHVzdWFyaW8gZW5pdG8K')
            self.send_header('Content-type', 'text/html')  # change at will
            self.end_headers()

        @property
        def _filepath(self):
            filename = quote(self.path.strip('/'), safe='')
            return os.path.join(TEST_LOCATION, '{0}.html'.format(filename))

        def _read_from_file_or_404(self):
            try:
                f = open(self._filepath, 'rb')
            except FileNotFoundError:
                self.send_response(404)
                self.wfile.write(b'\n<html><body>404 Not Found!</body></html>')
            else:
                self.send_response(200)
                # needs an extra new line
                self.wfile.write(b'\n' + f.read())
                f.close()

        def do_GET(self):
            self._set_headers()
            self._read_from_file_or_404()

        def do_POST(self):
            self._set_headers()
            self._read_from_file_or_404()

        def log_message(self, format, *args):
            """Do not write log messages to std. Disable to see the requests."""
            return


    def get_free_port(hostname):
        s = socket.socket(socket.AF_INET, type=socket.SOCK_STREAM)
        s.bind((hostname, 0))
        address, port = s.getsockname()
        s.close()
        return port


    def start_mock_server(hostname='localhost', port=None):
        if port is None:
            port = get_free_port(hostname)
        mock_server = HTTPServer((hostname, port), MockServerRequestHandler)
        mock_server_thread = Thread(target=mock_server.serve_forever)
        mock_server_thread.setDaemon(True)
        mock_server_thread.start()
        return '{hostname}:{port}'.format(hostname=hostname, port=port)

And finally the base test from which you will inherit, whenever you need to test the scrapper.

.. code-block:: python

    import unittest
    from my_project import const
    from tests import start_mock_server  # or where you saved it


    class BaseScrapperTest(unittest.TestCase):

        @classmethod
        def setUpClass(cls):
            url = start_mock_server()
            const.HOSTNAME = url

Take a look at that last line, your project must have a central point where the **HOSTNAME** is set.
Before testing, you need to tell to your application to hit your localserver.


Final notes
------------

If you find hard to test some scrapper function, try dividing it into smaller functions, and testing
them individually.

If a scrapper function does not include any condition, it's okay to :code:`return True` at the end,
and assert that boolean. If something goes wrong in the scrapper, we'll get noticied with an exception
and the test will throw an error. Also, if you wanted to `receive a fail <https://stackoverflow.com/a/4319870/2047185>`_
instead of an error, which is more pythonic, you should do something like this in your test:

.. code-block:: python

    try:
        users_from_github()
    except ExceptionType:
        self.fail("users_from_github() raised ExceptionType unexpectedly!")

Try isolating the scrapper as much as possible from the rest of your project, whenever you need
to use selenium, avoid including bussiness logic in it as well, this difficults testing and makes
the code quite confusing.

Regards!
