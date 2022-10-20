<!--
.. title: A Rust web app with HTML templates
.. slug: web-app-with-template-in-rust
.. date: 2022-10-16 15:27:25 UTC
.. tags: rust, templates, jinja, networking
.. category: rust
.. link:
.. description: Writing a web application in rust using axum and minijinja. If you have used jinja2 in the past this will feel familiar. But we also dig into protocols and networking.
.. type: text
-->

The other day, I was helping my girlfriend with Go templates in a web server, and the internet is full of tutorials and explanations. And I thought, what about doing the same in Rust? How hard can it be?

Spoilers: it's easy, but there's not much information around

Let's change that!

## The stack

If you come from a language with a big standard library like Go, you should know that rust is a bit more lightweight. The language has decided to provide a slim std library with a top of the line package manager and tools. It's up to the community to provide packages like web servers or templating.

If you come from Python, even though there's a big standard library, when doing web, is not used by developers. Instead, you are probably used to libraries like Django, Jinja2 or Fastapi. If that's the case, you are gonna feel familiar with the following stack.

This makes me wonder... will Go end up in the same direction as python? Is there something in the standard library that the community doesn't use, and instead, relies on a third party package? Anyways...

If you come from Javascript, I pity you.

Let's get back to our stack.

### Axum

[Axum] is one of the favorite web frameworks in the rust landscape. It's not as mature as Actix Web (which continues to rock). But it's getting a lot of traction, because of it's great integration with tokio and its ecosystem. [Axum] was created by [David Pedersen](https://github.com/davidpdrsn) from [EmbarkStudios](https://github.com/EmbarkStudios). This company seems to be taking rust to the next level 🙌🏼 🚀.

[Axum]: https://github.com/tokio-rs/axum

### Minijinja

[Minijinja] is the rust implementation of Python's Jinja2 by the very same awesome author: [mitsuhiko](https://lucumr.pocoo.org/). A lot of people are already familiar with it and with good reason, it's easy to use.

[Minijinja]: https://github.com/mitsuhiko/minijinja/

### Tokio

The most popular async runtime. It's ideal for writing network applications. Like our web app, built with Axum.
[Tokio] has a big ecosystem, from tracing to database drivers.

[Tokio]: https://tokio.rs/

### Serde

[Serde] again, is the most popular way to serialize and deserialize data structures in rust. You serialize or deserialize from one format to another. For example, if you receive a JSON as bytes from an HTTP request, with serde you are going to be able to read the different fields, or load some of that information into a `struct`.

[Serde]'s most common way to use is to derive the `Serialize` or `Deserialize` macros in your `struct`. From there,
you can probably read from, or serialize into different formats, many implemented by the community. Some of the list include JSON, TOML, AVRO, and more.

In our case, minijinja requires the `Serialize` macro in our structs to render the templates.

[Serde]: https://serde.rs/

## Set up

You've already [installed rust](https://www.rust-lang.org/tools/install), so go to your projects folder
and create a new rust project.

```sh
cargo new web-template-rs
cd web-template-rs/
```

With the following dependencies.

```sh
cargo add axum \
    tokio -F tokio/full \
    serde -F serde/derive \
    minijinja -F minijinja/builtins
```

We use the `-F` flag to signal which features to include from those crates.

## The Code

We are now ready to start. And we won't need anything else.

A simple webserver retuning HTML without a template looks something like this:

```rust
use axum::{response::Html, routing::get, Router};

async fn home() -> Html<&'static str> {
    Html("hello world")
}

#[tokio::main]
async fn main() {
    // build our application with a single route
    let app = Router::new()
        .route(
            "/",
            get(home),
        );

    // run it with hyper on localhost:3000
    axum::Server::bind(&"0.0.0.0:3000".parse().unwrap())
        .serve(app.into_make_service())
        .await
        .unwrap();
}
```

To run our application we run

```sh
cargo run
```

Because we haven't configured any logging, you won't see anything in your terminal after running, that's fine.
If you want to learn how to do it, check the [tracing-example](https://github.com/tokio-rs/axum/tree/main/examples/tracing-aka-logging).

In the meanwhile, in your browser go to `0.0.0.0:3000` and observe the "hello world" text.

### What has happened here?

When you type a URL or IP in the browser and press <kbd>enter</kbd>, the browser will "craft"
a GET HTTP request, and send it over a TCP connection to the given IP. If you provide a URL instead (`www.example.com`), the browser would have to resolve the IP through DNS. But in our case, we are using directly an IP.

What are all these acronyms? [TCP], [IP], [HTTP], [DNS]. They are all Internet Standards. Conventions to guarantee interoperability, they make the internet work. Then is up to people to make actual tools around those protocols. If you want your coffee machine to communicate over the internet, when you start coding its code, you will have to handle all those protocols (or find libraries that already do it for you).

[DNS]: https://www.rfc-editor.org/rfc/rfc1035.html
[TCP]: https://www.ietf.org/rfc/rfc793.html
[IP]: https://www.rfc-editor.org/rfc/rfc791.html
[HTTP]: https://www.rfc-editor.org/rfc/rfc2616

Remember: **HTTP is plain text**

The request your browser will craft, will look something like this:

```http
GET / HTTP/1.1
Host: localhost:3000
User-Agent: Mozilla/5.0
Accept: */*
```

And it will be sent over the internet inside an HTTP request, which itself will travel inside a TCP packet, which itself travels inside an IP packet. But actually, we are doing this on our local machine, so it won't reach the internet, your computer knows there is someone listening to `0.0.0.0` right away.

```
   IP
 ┌────────────────────────────────┐
 │          TCP                   │
 │         ┌──────────────────────┤
 │         │           HTTP       │
 │         │          ┌───────────┤
 │         │          │  GET /    │
 └─────────┴──────────┴───────────┘
```

The request will be received by our rust web server, and it will attempt to handle the "requested" path (`GET /`).
No matter what language you use: rust, python, go, js, etc. requests are all plain text.

Our rust web server, actually knows how to handle that request, because it includes a `route`

```rs
// ...
.route(
    "/",
    get(home),
);
```

[Axum] sees the `/` and it know it has a function to handle that path. That function actually means something like

> return an HTTP response containing HTML with the text "hello world"

And what will axum create? **a plain text HTTP response**

```http
HTTP/1.1 200 OK
content-type: text/html; charset=utf-8
content-length: 11
date: Mon, 17 Oct 2022 08:03:24 GMT

hello world
```

Your browser will receive the response and render a nice white background with the given text.

Enough with networking lessons woile! I want to know how to use templates.

True, true... I forgot where were we going with all this... but do we know what templates are?

## Templates

Or... a monstrosity. You mix a "custom language", with your target language. This way, you can output the target language from a different one. Let's say we want to create an HTML with a list of users from rust, python or go:

```html
<ul>
    <li>Timmy</li>
    <li>Benji</li>
    <li>Mimi</li>
</ul>
```

What happens when we have a new user? We would have to edit it manually, right? Can we make this behave "dynamically" instead?

Yes, using templates. Minijinja is a rust implementation of the popular python's `jinja2`. A popular "template engine" with its own language. There are endless template engines, and they don't share the same syntax. Python django's template engine, go templates, JSX (right?), lodash templates, and more. They end up being similar, they have a way to iterate, show data, or use an if condition.

Now with a template engine, we can write something like this:

```html
<ul>
    {% for user in users %}
    <li>user.name</li>
    {% endfor %}
</ul>
```

This way, our fictional user service, can take this template, fetch the users, and passing through the template, render the list of users.

Why are templates a monstrosity? Well because, most of the time, the tooling around them is not good, and you don't get an error until you actually try to render them. If you use Kubernetes, its famous package manager "Helm", uses templates on top of YAML. YAML is already a [controversial language](https://noyaml.com/), but add a template layer on top and it becomes incredibly hard to read and maintain.

## Axum with templates

Back to our web application! This time, we are gonna create 2 fictional `structs`, that we'll use as examples.

```rs
use serde::Serialize;

#[derive(Debug, Serialize)]
struct Items {
    id: i32,
    name: String,
}

#[derive(Debug, Serialize)]
struct Profile {
    full_name: String,
    items: Vec<Items>,
}
```

You can see we are using serde's `Serialize`, so minijinja can use them. And `Profile.items` is a `Vec`, this way we can showcase an iteration example in the template.

As we've seen templates, we are ready to write our jinja2 like template in rust.

```rust
const PROFILE_TEMPLATE: &'static str = r#"
<!doctype html>

<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">

  <title>A Basic HTML5 Template</title>
  <meta name="description" content="A simple HTML5 Template for new projects.">
  <meta name="author" content="Woile">
</head>

<body>
    <h1>Profile of {{ profile.full_name|title }}</h1>
    <p>This is a template example to show some functionality</p>
    <h2>Items</h3>
    <ul>
        {% for item in profile.items %}
        <li>{{ item.name }} ({{ item.id }})</li>
        {% endfor %}
    <ul>
</body>
</html>
"#;
```

Right in the body of the HTML, we show the `profile.full_name`, and then we iterate over each item, displaying the `name` and the `id`.

And for Axum, we add a new route, that will create some example structs.

```rs
use axum::{response::Html, routing::get, Router, extract::Path};
use minijinja::render;

async fn home() -> Html<&'static str> {
    Html("hello world")
}

async fn get_profile(Path(profile_name): Path<String>) -> Html<String> {
    let orders_example = vec![
        Items {
            id: 1,
            name: "Article banana".into(),
        },
        Items {
            id: 2,
            name: "Article apple".into(),
        },
    ];
    let profile_example = Profile {
        full_name: profile_name,
        items: orders_example,
    };
    let r = render!(PROFILE_TEMPLATE, profile => profile_example );
    Html(r)
}

#[tokio::main]
async fn main() {
    let app = Router::new()
        .route(
            "/",
            get(home),
        )
        .route(
            "/:profile_name",
            get(get_profile),
        );
    // run it with hyper on localhost:3000
    axum::Server::bind(&"0.0.0.0:3000".parse().unwrap())
        .serve(app.into_make_service())
        .await
        .unwrap();
}
```

Too complicated?

Let's take a look at this 2 lines:

```rust
"/:profile_name",
get(get_profile),
```

The first line is the `path`, which is a the root `/` + a variable value `:profile_name`.
And right in the next line, we call the `get_profile`, which we can see how it uses the `profile_name` variable, extracted from the `path`.

After that, we create the example `structs`. In a real example, that information would probably come from a database.

And then, inside the `get_profile` we have:

```rust
let r = render!(PROFILE_TEMPLATE, profile => profile_example );
Html(r)
```

Where `render!` is minijinja's macro, that receives the template we previous declared, and then we provide some kind of "map" between the variables used in the template first, and then the rust variable.

A downside here is, that if we have an error in our template, we are only going to see it during runtime.
But on the bright side, this introduction was a quick way to get started with templates and axum in Rust.

The code is available on [github.com/woile/web-template-rs-example](https://github.com/woile/web-template-rs-example)

> Hey, hello 👋
>
> Interested in what I write? follow me on [twitter][santiwilly]
>

[santiwilly]: https://twitter.com/santiwilly
