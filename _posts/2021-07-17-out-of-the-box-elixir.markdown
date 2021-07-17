---
layout: post
title: Out of the Box Elixir
date: 2021-07-17 17:20
comments: false
permalink: /blog/2021/07/17/out-of-the-box-elixir
---

[Last time](/blog/2016/07/17/4-plus-years-of-using-minitest) I wrote about 4+ years of using Minitest, how about I write about 5+ years of using Elixir now? It is going to be a little bit about that. But first, some background.

I don't remember exactly but I am pretty sure the very first program I ever wrote was a PHP script. I was able to run it thanks to some kind of WAMP package (Windows Apache MySQL PHP) I installed from a CD-ROM that came with a gaming magazine. (The magazine is called CD-Action and it is still around!) All I needed to write and run the program was: a text editor (Notepad.exe at the time, not even Notepad+ until some time later!), that WAMP package, and a Web browser. Make a change to `index.php`, hit `F5` in the browser, and that's it. I didn't know anything about algorithms, data structures, or compilers but I was able to move forward and slowly learn how to program, one `ctrl+s` and `alt+tab` and `F5` at a time.

Pretty good out of the box experience.

Then I learned about Ruby and Ruby on Rails and it opened my eyes to some many things. On the Ruby side, the `irb` interactive shell, the `rake` build tool, the `ri` documentation tool, the `test/unit` test framework, RubyGems, and so much more. On the Rails side, convention over configuration, scaffolding, database migrations, and so much more as well.

Pretty good out of the box experience too.

I've first heard about Elixir in 2013-2014 and I have been using it profesionally since 2016. On the language side, I've been blown away by pattern matching, macros, and protocols. (I've dabbled in Clojure and Haskell at the time, so these were not entirely new concepts to me, but they were definitely put together in a more friendly manner.) On the tooling side, I've found the [IEx](https://hexdocs.pm/iex/IEx.html) shell (especially the `iex> h` integrated documentation!), the [Mix](https://hexdocs.pm/mix/Mix.html) build tool, the [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html) test framework (especially doctests!) to all be really powerful yet easy to use and work together really well. Outside of core we have the well known projects like [Phoenix](https://www.phoenixframework.org), [Ecto](https://github.com/elixir-ecto/ecto) and [Nerves](http://nerves-project.org), and lesser known ones for about any common programming task, hosted on [Hex](https://hex.pm). More recently we got [Phoenix LiveView](http://github.com/phoenixframework/phoenix_live_view) which enables rich and real-time user experiences with server-rendered HTMLs, and [Phoenix LiveDashboard](https://github.com/phoenixframework/phoenix_live_dashboard), real-time performance monitoring and debugging dashboard for your Phoenix app. Even more recently we got [Nx](https://github.com/elixir-nx/nx) and [Axon](https://github.com/elixir-nx/axon), tools for high-performance computing and neural networks, and [Livebook](https://github.com/livebook-dev/livebook). The community definitely keeps growing in new and exciting directions. Oh, and all of this is built on [Erlang](https://erlang.org) which powers some of the most demanding and most reliable systems in the world.

Speaking of [Livebook](https://github.com/livebook-dev/livebook), I think it in particular can really contribute to the success of Elixir and getting a next generation of developers aboard. Livebook is an interactive editor, you can edit and execute your Elixir code all in one place. It's a bit like that `ctrl+s / F5` workflow I mentioned at the beginning, it's really easy to tinker with your program. Seriously, if you haven't tried it, do it!

If you already have Elixir installed, starting Livebook is as simple as:

    $ mix escript.install hex livebook
    $ livebook server --open

If you don't have Elixir installed, but you have [Docker](https://www.docker.com), it's just:

    $ docker run -p 8080:8080 livebook/livebook

While of course nowhere near as popular as PHP or Ruby, I think it is fair to say that Elixir has also a pretty good out of the box experience too.

At the end of the article I'll share some of my ideas to hopefully make the experience even better. First, though, let's write a simple program in a couple of different languages.

## A simple program

The program's job is to download some JSON from the Web, parse it, extract some information from it, and finally print it.

I'm running macOS but the experience should be pretty similar across other major OSes.

[curl](https://curl.se) + [jq](https://stedolan.github.io/jq/):

```
$ brew install jq
$ curl --silent https://api.github.com/repos/curl/curl | jq -r .description
```

Outputs:

```
A command line tool and library for transferring data with URL syntax, supporting DICT, FILE, FTP, FTPS, GOPHER, GOPHERS, HTTP, HTTPS, IMAP, IMAPS, LDAP, LDAPS, MQTT, POP3, POP3S, RTMP, RTMPS, RTSP, SCP, SFTP, SMB, SMBS, SMTP, SMTPS, TELNET and TFTP. libcurl offers a myriad of powerful features
```

[Ruby](http://www.ruby-lang.org):

```
$ ruby -e 'require "net/http"; require "json"
    url = "https://api.github.com/repos/ruby/ruby"
    puts JSON(Net::HTTP.get(URI(url)))["description"]'
```

Outputs:

```
The Ruby Programming Language [mirror]
```

[Python](https://www.python.org):

```
$ python3 -c 'import urllib.request; import json
url = "https://api.github.com/repos/python/cpython"
print(json.loads(urllib.request.urlopen(url).read())["description"])'
```

Outputs:

```
The Python programming language
```

[Python](https://www.python.org) with [Requests](https://docs.python-requests.org):

```
$ pip3 install requests --user
$ python3 -c 'import requests
url = "https://api.github.com/repos/python/cpython"
print(requests.get(url).json()["description"])'
```

Outputs:

```
The Python programming language
```

[Elixir](https://elixir-lang.org) with [Req](https://github.com/wojtekmach/req):

```
$ brew install elixir
$ elixir -e 'Mix.install([:req])
    url = "https://api.github.com/repos/elixir-lang/elixir"
    IO.puts Req.get!(url).body["description"]'
```

Outputs:

```
Elixir is a dynamic, functional language designed for building scalable and maintainable applications
```

Full disclosure: I'm the author of Req. :) There are obviously other excellent HTTP clients in the Erlang/Elixir ecosystem!

While Elixir is not traditionally associated with scripting languages, you can see that for this particular and totally arbitrary problem, it works pretty well too.

## Another simple program and what it takes to run it

Let's change our program slightly, now we'll download some markdown and convert it to HTML. Here it is:

```
$ elixir -e 'Mix.install([:req, :cmark])
    url = "https://raw.githubusercontent.com/elixir-lang/elixir/master/README.md"
    Req.get!(url).body |> Cmark.to_html() |> IO.puts()'
```

The [Cmark Hex package](https://github.com/asaaki/cmark.ex) is an Elixir wrapper over [cmark](https://github.com/commonmark/cmark), the C reference implementation of the [CommonMark](http://commonmark.org) Markdown specification.

The Cmark Hex package vendors some C files that will be compiled on your machine when installing the package. It means that you need a C compiler which most likely is not a problem, most likely you already have it. However, there are situations when running Elixir code that you may not have the C compiler installed. For example, when running Livebook with Docker as mentioned earlier, `$ docker run -p 8080:8080 livebook/livebook`, we would not be able to `Mix.install([:cmark])`, the Livebook Docker container does not have C compiler toolchain installed at the moment.

Then there is the question of getting Elixir in the first place. As show in the article, we can `brew install elixir` it (or `apt install elixir` it, `choco install elixir` it, etc) but at least on a Mac, you need to first install Homebrew. Which is fine and easy but...

What if in order to run the above mentioned snippet you don't need to have, or even know what is, Homebrew or Docker or a C compiler or anything like that? What if you don't have any programming experience whatsoever but you can get a single program e.g. from a CD-ROM (wait, what is a CD-ROM again?) and have everything you need to develop Elixir? To sum up, we need:

1. [x] An easy way to install Hex packages (`Mix.install`)
2. [x] An easy to use HTTP client (Req)
3. [ ] A "one-click" Elixir installer that works on a fresh operating system
4. [ ] A way to install packages with native code without a C compiler

As you can see we have already made some progress but there is still a lot to do.

Stay tuned. :)

P.S.: For problem #3 I have an early prototype, elixir-run, but don't use it due to its [design flaws](https://github.com/wojtekmach/elixir-run/issues/1#issuecomment-876953302).
