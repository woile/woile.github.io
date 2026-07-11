+++
title = "Network programming in Rust"
description = "Rust and C comparisons for network programming"
date = 2024-05-20
tags = ["rust", "C", "networking"]
aliases = ["/posts/network-programming-in-rust"]
+++

I recently finished [Beej's Guide to Network Programming](https://beej.us/guide/bgnet/) and it was a very pleasant read.

Somehow the author manages to make writing sockets fun. While reading I decided to re-write the examples in `Rust`, to get some hands-on experience, which helps me absorb the content better.

You can find the code on github: [beej-rs](https://github.com/woile/beej-rs)

I remember studying `C` at university and always being worried about my code failing. Which it did, constantly. Not only because of the endless memory leaks or segfaults, but also because of the lack of tests.

Being a student, I had no idea where to start, and I have to say, I still don't know how to write tests in `C`. So I just executed the program multiple times, until it worked, for one or two scenarios.

The last couple of years, I've been writing `Rust`, and I developed a new love for low level programming. The contrast with `C` is amazing.

After installing the language, you get enough tools to survive:

- `cargo`: for package management, tests, etc
- `rust-analyzer`: the LSP ready to integrate with whichever IDE you are using
- `rust-docs`: ready to build all your code's documentation
- `rustfmt`: to keep your code style consistent

Now, in regards of the languages, let's make a short comparison of error handling in a scary `C` snippet with its `Rust` counterpart.

All the system calls you make, they *may* return an error, and how do you know in `C`?

Well... the integer returned by a function will have different meanings:

For the [sendto](https://linux.die.net/man/2/sendto) syscall:

- `>=0`: number of bytes sent
- `-1`: go and look the error code, that `C` set in the global `errno` variable, which is write only to the system calls
- `<-1`: No idea, is it possible?

```c
numbytes = sendto(sockfd, argv[2], strlen(argv[2]), 0, (struct sockaddr *)&their_addr, sizeof their_addr)

if (numbytes == -1) {
	perror("sendto");
	exit(1);
}
```

On this sample, you need to know that `perror`, automatically reads the global error `errno` and then it prints the message.

And you **must NOT forget** to handle it, what happens otherwise? you continue the execution, probably causing catastrophic errors to planet Earth.

Let's take a look at rust:

```rust
let numbytes = nix::sys::socket::sendto(
    sockfd.as_raw_fd(),
    message.as_bytes(),
    &socket,
    nix::sys::socket::MsgFlags::empty(),
).expect("Testing sendto");
```

In this case, we use `Rust`'s `expect`, which will automatically fail the program if there's an error. And if all goes well, you get the `numbytes` sent.

Now, little details: `numbytes` is also an unsigned `usize`, which makes sense, because sending negative bytes would be strange.

And what would happen if we forget to use `expect`?

We would get a `Result<usize, Errno>`, meaning that, in order to use the number of bytes sent (`usize`), we must first do something to unpack it from the `Result`, forcing us to handle the error.

But what if we don't care about the output of the function, and we don't even assign it to a variable, like this:

```rust
nix::sys::socket::sendto(
    sockfd.as_raw_fd(),
    message.as_bytes(),
    &socket,
    nix::sys::socket::MsgFlags::empty(),
)
```

Then, you get a compiler warning:

```rust
warning: unused `Result` that must be used
  --> src/examples/talker.rs:52:13
   |
52 | /             nix::sys::socket::sendto(
53 | |                 sockfd.as_raw_fd(),
54 | |                 message.as_bytes(),
55 | |                 &socket,
56 | |                 nix::sys::socket::MsgFlags::empty(),
57 | |             )
   | |_____________^
   |
   = note: this `Result` may be an `Err` variant, which should be handled
   = note: `#[warn(unused_must_use)]` on by default
help: use `let _ = ...` to ignore the resulting value
   |
52 |             let _ = nix::sys::socket::sendto(
   |             +++++++
```

Which even tells you what to do if you **really really** wanna ignore the `Result`. But it also warns you into handling it.

Now, this is not to trash on `C`, which is a language that helped us build modern society. I want to highlight how good `Rust` is, which is a modern language, only possible because of all we've learned over the years. "we" as the human collective.

Going back to the book, here are my highlights:

- **IPv6 does not support broadcast like on IPv4**. You have to use **multicast**. I've heard about multicast, but it seemed a ethereal concept. Now I know that it's kind of like broadcast, but instead of sending to everyone, forcing every machine to decode the payload, and checking if it's for them by sending it to a port, instead, you just send it to "groups" of machines. And you could achieve essentially a broadcast using multicast.
- **Network Byte Order**: when you send data over the wire, always use `Big-Endian`, ignoring the host machine's byte order
- Prefer [nix](https://docs.rs/nix/0.28.0/nix/index.html) over [libc](https://docs.rs/libc/latest/libc/index.html) in Rust, as the bindings are safer
- A file descriptor it's just an integer pointing to a file
- File descriptor `0` is stdin, `1` is `stdout` and `2` is `stderr`
- A socket is a file descriptor, while a file descriptor is not a socket. When we say socket, we refer to a FD used for network communication

Cheers!

[@woile](https://hachyderm.io/@woile)
