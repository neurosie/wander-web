#!/bin/bash

WANDER_SRC_DIR="wander_src"
OUT_DIR="bin"
WANDER_OUT="$OUT_DIR/wander.js"
VENDOR_DIR="$OUT_DIR/vendor"
PTY_JS_LIBRARY="node_modules/xterm-pty/emscripten-pty.js"

if [[ ! -d $WANDER_SRC_DIR ]]; then
	git clone https://github.com/shmup/wander.git $WANDER_SRC_DIR
	$(cd $WANDER_SRC_DIR && git apply ../port.patch)
fi

if [[ ! -e $PTY_JS_LIBRARY ]]; then
	npm install
fi

DO_COMPILE=1

if [[ -e $WANDER_OUT ]]; then
	DO_COMPILE=0
	for file in $WANDER_SRC_DIR/*.{c,h}; do
		if [[ $file -nt $WANDER_OUT ]]; then
			$(cd $WANDER_SRC_DIR && git diff *.{c,h} > ../port.patch)
			DO_COMPILE=1
			break
		fi
	done
fi

if [[ $DO_COMPILE == 1 ]]; then
	rm -rf $OUT_DIR
	mkdir $OUT_DIR
	# ASYNCIFY lets xterm-pty pause the program while it waits on stdin, which
	# is what makes a blocking read loop work on the browser's main thread.
	emcc $WANDER_SRC_DIR/*.c \
		-std=gnu89 \
		-sASYNCIFY \
		-sFORCE_FILESYSTEM \
		-sEXIT_RUNTIME=1 \
		--js-library $PTY_JS_LIBRARY \
		--preload-file $WANDER_SRC_DIR/a3.misc \
		--preload-file $WANDER_SRC_DIR/a3.wrld \
		-w -o $WANDER_OUT
fi

mkdir -p $VENDOR_DIR
cp node_modules/@xterm/xterm/lib/xterm.js $VENDOR_DIR/xterm.js
cp node_modules/@xterm/xterm/css/xterm.css $VENDOR_DIR/xterm.css
cp node_modules/@xterm/addon-fit/lib/addon-fit.js $VENDOR_DIR/addon-fit.js
cp node_modules/xterm-pty/index.js $VENDOR_DIR/xterm-pty.js

ln -sf $(pwd)/src/* bin
