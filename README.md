# Wander web

Play\* the first ever\** text adventure game right in your browser.

\*see [Status](#status)  
\*\*https://bluerenga.blog/2015/04/23/wander-1974-release-and-questions-answered/

## Getting started
### Prerequisites
* git
* [Emscripten](https://emscripten.org/docs/getting_started/downloads.html)
* Node.js and npm (for the terminal front-end packages)
* Python 3 (optional)

### Installing

Download this repository:

```
git clone https://github.com/neurosie/wander-web
cd wander-web
```

And to build:
```
./build.sh
```

This will download, patch, and compile the [original Wander source](https://github.com/shmup/wander),
and copy the terminal front-end into `bin`.

### Running
Because of the way emscripten works, you can't just open `index.html` in your browser, you need a web server:

```
npm start
```

which serves `bin` on http://localhost:8000 (equivalent to running `python3 -m http.server` from `bin`).

## The terminal

Wander is an ordinary Unix terminal program: it writes to stdout and reads
commands from stdin one line at a time, and it does no cursor addressing of its
own. So instead of imitating a terminal with a `<textarea>`, the page gives it
a real one:

* **[xterm.js](https://xtermjs.org/)** draws the terminal.
* **[xterm-pty](https://github.com/mame/xterm-pty)** sits between xterm.js and
  the program and supplies the piece xterm.js deliberately leaves out: the
  **line discipline**. It implements termios, so canonical-mode line editing,
  echo, `^C`/`^D`/`^U`/`^W` and `TIOCGWINSZ` all behave the way the program
  expects, and none of that logic has to live in this repo.

The one thing a browser genuinely cannot do is let the program *block* inside
`read()` on the main thread. There are three ways out, and the build uses the
first:

1. **`-sASYNCIFY`** (what `build.sh` does). Emscripten rewrites the module so
   it can be suspended and resumed, and xterm-pty pauses it while it waits for
   a line. Works in every browser, needs no special HTTP headers. The known
   caveat -- output is only flushed when the program pauses -- costs nothing
   here, because Wander prints a screenful and then immediately waits for the
   next command.
2. **`-pthread -sPROXY_TO_PTHREAD`**, which runs the program in a worker and
   blocks it for real on `Atomics.wait`. Better for programs that print
   continuously, but it needs `SharedArrayBuffer`, which means serving
   `Cross-Origin-Opener-Policy` and `Cross-Origin-Embedder-Policy` headers --
   and GitHub Pages cannot set headers.
3. **`-sJSPI`**, which does what Asyncify does using native stack switching
   instead of a binary rewrite (smaller and faster). It is a one-flag swap once
   browser support is broad enough to drop the fallback.

## Status

The game logic runs and is playable: you can pick up the credit card, check your
balance and walk west into customs. Three things had to be fixed to get there,
all in `port.patch`:

* `wanddef.h` declared `struct paramstr { ... } param;` in the header, giving
  every translation unit a tentative definition of `param`. Compilers used to
  merge those (`-fcommon`); since clang 11 that is a duplicate-symbol link
  error. The definition now lives only in `wandglb.c`.
* `objdesc()` was defined with four parameters but called with six (the callers
  pass a buffer and its size). On a stack machine the extra arguments were
  harmless, but wasm checks signatures, so `wasm-ld` replaced every one of those
  calls with a trapping stub -- and `objdesc()` is called to describe the credit
  card lying in the very first room. It now takes the buffer its callers were
  already passing.
* The build needs `-std=gnu89`. This is 1974 K&R C: C23 removed old-style
  function definitions outright, so a modern clang default will eventually
  reject it.

## Acknowledgements
Thanks to Peter Langston for the original game, and for giving me permission to port it.
