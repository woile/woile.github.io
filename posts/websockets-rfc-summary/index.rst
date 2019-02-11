.. title: Websockets RFC summary
.. slug: websockets-rfc-summary
.. date: 2018-09-28 14:16:24 UTC-03:00
.. tags: rfc summary websockets
.. category: networking
.. link:
.. description: a
.. type: text
.. status: draft


`RFC <https://tools.ietf.org/html/rfc6455.html>`_
==================================================

Introduction
============

For bi-directional communication (e.g., instant messaging and gaming applications): abuse of **HTTP poll**.

Problems
--------

- mutiple TCP connections. One for sending information and a new one for each incoming message.
- each client-to-server message having an HTTP header.
- the client-side script is forced to maintain a mapping from the outgoing connections to the incoming connection to track replies

Solution
--------

**WebSocket Protocol** uses a single TCP connection for traffic in both directions.

Features
--------

- works over HTTP ports 80 and 443
- support for HTTP proxies and intermediaries
- design does not limit WebSocket to HTTP

Overview
========

Protocol has 2 parts: **handshake** & **data transfer**

Handshake
---------

**client** handshake example

::

    GET /chat HTTP/1.1
    Host: server.example.com
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
    Origin: http://example.com
    Sec-WebSocket-Protocol: chat, superchat
    Sec-WebSocket-Version: 13

**server** handshake example

::

    HTTP/1.1 101 Switching Protocols
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
    Sec-WebSocket-Protocol: chat

An unordered set of header fields comes after the leading line in both cases.
Additional header fields may also be present, such as cookies.

After a successful handshake, clients and servers transfer data back and forth in
conceptual units referred as **"messages"**.


Opening Handshake
~~~~~~~~~~~~~~~~~

* compatible with HTTP-based server-side
* handshake from server includes header with the status code **101**, otherwise handshake has not completed and that the semantics of HTTP still apply


Design philosophy
-----------------

The WebSocket Protocol is designed on the principle that there should
be minimal framing (the only framing that exists is to make the
protocol frame-based instead of stream-based and to support a
distinction between Unicode text and binary frames).

Relationship to TCP and HTTP
----------------------------

The WebSocket Protocol is an independent TCP-based protocol.  Its
only relationship to HTTP is that its handshake is interpreted by
HTTP servers as an Upgrade request.


WebSocket URIs
===============

two URI schemes (insecure & secure)

::

    ws-URI = "ws:" "//" host [ ":" port ] path [ "?" query ]
    wss-URI = "wss:" "//" host [ ":" port ] path [ "?" query ]

* port component is OPTIONAL
* default for "ws" is port 80,
* default for "wss" is port 443.
* fragment identifiers (#) are meaningless in the context of WebSocket URIs and MUST NOT be used on these URIs, escape them using %23 if needed.


Data Framing
============

* client **MUST** mask all frames that it sends to the server
* server **MUST** close the connection upon receiving a frame that is not masked.
* server **MAY** use the status code 1002 to close connection
* server **MUST NOT** mask any frames that it sends to the client.
* client **MUST** close a connection if it detects a masked frame.
* client **MAY** use the status code 1002 to close connection
