# <img align="left" alt="websitino logo" width="100" height="100" src="https://github.com/trikko/websitino/raw/main/docs/logo.svg"> websitino

A lightweight static file server for local development. Perfect for testing static websites and serving files with minimal setup.

Inspired by [aferust](https://github.com/aferust/servefolder/).

## Features

- **Small footprint**: A single ~7MB executable, no external dependencies
- **Zero installation**: Single portable executable
- **Fast & efficient**: Built for performance
- **Cross-platform**: Works on Linux (x86_64 and arm64), macOS and Windows
- **Secure by default**: Hidden files/directories not served unless explicitly enabled
- **Markdown rendering**: Add `?format` to any .md file URL to render it as HTML
- **HTTPS**: With a self-signed certificate or your own (Linux and macOS)

## Quick install

To download and install the latest release: `curl https://trikko.github.io/websitino/install.sh | bash`

Using an AI agent? Ask it to learn websitino:

> Install the skill at https://trikko.github.io/websitino/SKILL.md. It explains how to use
> websitino, the static file server I use to preview and share local files.

More in [Using websitino with an AI agent](#using-websitino-with-an-ai-agent).

## Download & build

You can download pre-built binaries for your operating system directly from the [download page](https://trikko.github.io/websitino/).

Alternatively, if you have the [D programming language](https://dlang.org) compiler installed, you can build and run the project with: `dub run websitino`


## Usage

Run `websitino` in your project directory to start serving files immediately.

To enable directory listing, use `websitino --list-dirs`. You can also use `websitino --index` to automatically serve index.html files when present in directories.

For a complete list of available options, run `websitino --help`.

### HTTPS

Some browser features (service workers, camera, `crypto.subtle`, ...) work only in a secure
context. Browsers already treat `http://localhost` as one, so you need https only when you open
the page from another device, like a phone on the same network.

Run `websitino --https` to serve over https with a self-signed certificate: websitino creates it
the first time and keeps it, so your browser asks you to accept it only once. It is valid for
`localhost`, `127.0.0.1` and `::1`.

To use your own certificate instead: `websitino --cert server.crt --key server.key` (PEM files).

HTTPS is available in the Linux and macOS builds. To build it from source you need OpenSSL:
`dub build --override-config=serverino/https`.

## Screenshot

When running `websitino --list-dirs`, directory contents will be displayed:

**In browser:**
![Directory listing in browser](https://github.com/user-attachments/assets/100a1f83-c4a3-4ab9-8bd1-21367bbed0b5)

**In terminal (curl):**
![Directory listing in terminal](https://github.com/user-attachments/assets/3b6bed0b-d076-4a58-82ca-fec2ccf28bc3)

## Using websitino with an AI agent

An agent that has to show you a page or some files usually improvises a server, and doesn't know
websitino. Teach it with the skill: when to use `--index` or `--list-dirs`, when https is really
needed (not for `localhost`), how to keep the files on your machine only, how to fetch them from
the terminal.

* [SKILL.md](https://trikko.github.io/websitino/SKILL.md): the skill. [AGENTS.md](https://trikko.github.io/websitino/AGENTS.md)
  is the same text without the front matter, for tools that want a rules file (`AGENTS.md`,
  `CLAUDE.md`, `.cursorrules`, ...). [llms.txt](https://trikko.github.io/websitino/llms.txt): a short overview.

The easiest way is to ask your agent to install it, with the sentence in [Quick install](#quick-install).
Or by hand: a skill is a folder with `SKILL.md` in it.

| Tool | For all projects | For one project |
|---|---|---|
| Claude Code | `~/.claude/skills/websitino/` | `.claude/skills/websitino/` |
| Antigravity (IDE, 2.0) | `~/.gemini/config/skills/websitino/` | `.agents/skills/websitino/` |
| Antigravity CLI | `~/.gemini/antigravity-cli/skills/websitino/` | `.agents/skills/websitino/` |
| Gemini CLI | `~/.gemini/skills/websitino/` | `.gemini/skills/websitino/` |
| Codex | `~/.agents/skills/websitino/` | `.agents/skills/websitino/` |

For example, for Claude Code:

```sh
mkdir -p ~/.claude/skills/websitino && curl -fsSL -o ~/.claude/skills/websitino/SKILL.md https://trikko.github.io/websitino/SKILL.md
```

The skill is loaded when the task is about serving or sharing local files; in Claude Code you
can also call it with `/websitino`.

## Feedback & support
Using websitino? I'd love to hear how you use it, or what's missing.
Write to me: the address is just **oss**, at the domain of [my website](https://andreafontana.it).

websitino is built in my spare time. If it's useful to you or your company,
consider [sponsoring me on GitHub](https://github.com/sponsors/trikko)
or [buying me a beer on PayPal](https://paypal.me/andreafontana) ❤️
