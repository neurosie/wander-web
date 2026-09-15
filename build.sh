#!/bin/bash

WANDER_SRC_DIR="wander_src"
OUT_DIR="bin"
WANDER_OUT="$OUT_DIR/wander.js"
VENDOR_DIR="$OUT_DIR/vendor"
PTY_JS_LIBRARY="node_modules/xterm-pty/emscripten-pty.js"

if [[ ! -d $WANDER_SRC_DIR ]]; then
	git clone https://github.com/shmup/wander.git $WANDER_SRC_DIR || exit 1
	(cd $WANDER_SRC_DIR && git apply ../port.patch) || exit 1
fi

if [[ ! -e $PTY_JS_LIBRARY ]]; then
	npm install
fi

DO_COMPILE=1

if [[ -e $WANDER_OUT ]]; then
	DO_COMPILE=0
	for file in $WANDER_SRC_DIR/*.{c,h}; do
		if [[ $file -nt $WANDER_OUT ]]; then
			(cd $WANDER_SRC_DIR && git diff *.{c,h} > ../port.patch)
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
		-w -o $WANDER_OUT || exit 1
fi

# A missing wander.js used to sail through: the script ends in `ln -sf`, so a
# failed compile exited 0 and left a bin/ that served a 404 for the module.
if [[ ! -e $WANDER_OUT ]]; then
	echo "build.sh: $WANDER_OUT was not produced" >&2
	exit 1
fi

mkdir -p $VENDOR_DIR
cp node_modules/@xterm/xterm/lib/xterm.js $VENDOR_DIR/xterm.js || exit 1
cp node_modules/@xterm/xterm/css/xterm.css $VENDOR_DIR/xterm.css || exit 1
cp node_modules/@xterm/addon-fit/lib/addon-fit.js $VENDOR_DIR/addon-fit.js || exit 1
cp node_modules/xterm-pty/index.js $VENDOR_DIR/xterm-pty.js || exit 1

ln -sf $(pwd)/src/* bin
