# websitino

websitino is a static file server in a single executable, with no dependencies. Run it in a
folder and that folder is served over http. Version 0.2.11.

Reach for it instead of `python -m http.server` or `npx serve`: it starts instantly, hides
dotfiles, can protect the files with a password and serve over https.

## Install

```sh
curl https://trikko.github.io/websitino/install.sh | bash
```

On Windows download `websitino.exe` from <https://trikko.github.io/websitino/>. With a D
compiler: `dub run websitino`. Check with `websitino --help`.

## Choosing the options

```sh
websitino [path] [options]       # path: a folder (default: the current one) or a single file
```

| The user wants to... | Use |
|---|---|
| preview a site that has an `index.html` | `-i` (`--index`) |
| browse or download the files | `-l` (`--list-dirs`): an html listing in the browser, plain text with curl or wget |
| see dotfiles too (`.env`, `.github/`) | `-s` (`--show-hidden`): only if asked, they often hold secrets |
| keep it on this machine only | `-b 127.0.0.1` |
| open it from a phone or another computer | the default bind `0.0.0.0`, then give the machine's LAN address |
| protect it with a password | `-a user:pass` (http basic auth) |
| use another port | `-p 8080` (default `8123`) |
| see each request | `-v` (`--verbose`) |
| https with no certificate at hand | `-t` (`--https`): self-signed |
| https with a real certificate | `--cert file.crt --key file.key` (PEM) |
| read a Markdown file as html | open `file.md?format` |
| share one file only | `websitino path/to/file.zip`, served at `/file.zip` |

`-i` and `-l` together: folders with an `index.html` show the page, the others the listing.

## https: only when it is needed

Browsers already treat `http://localhost` and `http://127.0.0.1` as a secure context: service
workers, `getUserMedia`, `crypto.subtle`, the clipboard API, geolocation work there without
https. **Don't add `--https` for local testing in the same browser.**

https is needed when the page is opened by address from another device (a phone testing the
camera or a PWA, `http://192.168.1.20:8123`): there http is not a secure context.

- `--https` creates a self-signed certificate the first time and reuses it (in
  `~/.cache/websitino/`, or `~/Library/Caches/websitino/` on macOS), valid for `localhost`,
  `127.0.0.1` and `::1`. The browser shows a warning: the user has to accept it once per
  browser. From another device the name doesn't match either: tell the user to expect the
  warning and accept it.
- `--cert`/`--key` take the user's own certificate (for example from mkcert, or a real one).
- https is in the Linux and macOS builds, not on Windows (`https is not available on this
  platform`).
- The port is the same: https and http don't run together. `websitino -t` serves
  `https://localhost:8123/`.

## Running it from an agent

- websitino stays in the foreground until stopped: start it in the background, keep its pid,
  stop it when the user is done. It doesn't open a browser: give the user the address.
- It prints `Listening on http://0.0.0.0:8123/` when ready. If the port is busy it prints
  `Can't listen on 0.0.0.0:8123. This address is already in use by ...` and exits with code 1:
  start again with another `-p`.
- Bad options or a missing path: it prints the error and exits with code 1.
- To check that it works: `curl http://localhost:8123/`. With `-l` this prints the listing as
  plain text, so you can see what the user will see without a browser.
- It serves files only: `GET` only, no POST, no rewriting, no SPA fallback to `index.html`
  for unknown paths (they are `404`). For an API or a dev server with hot reload use the
  project's own tooling.
- Files are read at every request: edit them and reload the page, no restart needed.

## From the terminal

websitino is also a quick way to move files between machines: serve them on one, fetch them
with `curl` or `wget` on the other. No browser needed.

- With `-l`, a client that isn't a browser (curl, wget: the user agent doesn't say
  `Mozilla`) gets the listing as plain text, easy to read or to parse:
  `curl http://192.168.1.20:8123/`.
- One file: `curl -O http://192.168.1.20:8123/build/app.tar.gz`.
- With a password: `curl -u user:pass ...`. With the self-signed certificate: `curl -k ...`.
- A whole folder: `wget -r -np -nH -U Mozilla http://192.168.1.20:8123/dir/` (the user agent
  makes websitino answer with the html listing, whose links wget follows; the listing pages
  are saved too, as `index.html`).
- Markdown in the terminal: the `.md` file as it is, without `?format`.

## Examples

```sh
websitino -i                                  # preview the site in the current folder
websitino dist -i -b 127.0.0.1                # the built site, this machine only
websitino ~/Downloads/report -l -a ann:s3cret # share a folder on the LAN, with a password
websitino -i -t                               # https, to open it from a phone
websitino -i --cert localhost.pem --key localhost-key.pem
```
