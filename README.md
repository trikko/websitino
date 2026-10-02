# <img align="left" alt="websitino logo" width="100" height="100" src="https://github.com/trikko/websitino/raw/main/docs/logo.svg"> websitino

A lightweight static file server for local development. Perfect for testing static websites and serving files with minimal setup.

Inspired by [aferust](https://github.com/aferust/servefolder/).

## Features

- **Tiny footprint**: Only ~1.5MB, no external dependencies
- **Zero installation**: Single portable executable
- **Fast & efficient**: Built for performance
- **Cross-platform**: Works on Linux, macOS and Windows
- **Secure by default**: Hidden files/directories not served unless explicitly enabled
- **Markdown rendering**: Add `?format` to any .md file URL to render it as HTML

## Quick install

To download and install the latest release: `curl https://trikko.github.io/websitino/install.sh | bash`

## Download & build

You can download pre-built binaries for your operating system directly from the [download page](https://trikko.github.io/websitino/).

Alternatively, if you have the [D programming language](https://dlang.org) compiler installed, you can build and run the project with: `dub run websitino`


## Usage

Run `websitino` in your project directory to start serving files immediately.

To enable directory listing, use `websitino --list-dirs`. You can also use `websitino --index` to automatically serve index.html files when present in directories.

For a complete list of available options, run `websitino --help`.

## Screenshot

When running `websitino --list-dirs`, directory contents will be displayed:

**In browser:**
![Directory listing in browser](https://github.com/user-attachments/assets/100a1f83-c4a3-4ab9-8bd1-21367bbed0b5)

**In terminal (curl):**
![Directory listing in terminal](https://github.com/user-attachments/assets/3b6bed0b-d076-4a58-82ca-fec2ccf28bc3)

## Feedback & support
Using websitino? I'd love to hear how you use it, or what's missing.
Write to me: the address is just **oss**, at the domain of [my website](https://andreafontana.it).

websitino is built in my spare time. If it's useful to you or your company,
consider [sponsoring me on GitHub](https://github.com/sponsors/trikko)
or [buying me a beer on PayPal](https://paypal.me/andreafontana) ❤️
