# Wander web

Play\* the first ever\** text adventure game right in your browser.

\*not currently in a playable state  
\*\*https://bluerenga.blog/2015/04/23/wander-1974-release-and-questions-answered/

## Getting started
### Prerequisites
* git
* [Emscripten](https://emscripten.org/docs/getting_started/downloads.html)
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

This will download, patch, and compile the [original Wander source](https://github.com/shmup/wander).

### Running 
Because of the way emscripten works, you can't just open `index.html` in your browser, you need a web server. The easiest way to do this is to run `python3 -m http.server` from the `bin` directory.
