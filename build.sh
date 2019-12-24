#!/bin/bash

WANDER_SRC_DIR="wander_src"
OUT_DIR="bin"
WANDER_OUT="$OUT_DIR/wander.js"

if [[ ! -d $WANDER_SRC_DIR ]]; then
	git clone https://github.com/shmup/wander.git $WANDER_SRC_DIR
	cd $WANDER_SRC_DIR
	git apply ../port.patch
	cd ..
fi

DO_COMPILE=1

if [[ -e $WANDER_OUT ]]; then
	DO_COMPILE=0
	for file in $WANDER_SRC_DIR/*.{c,h}; do
		if [[ $file -nt $WANDER_OUT ]]; then
			DO_COMPILE=1
			break
		fi
	done
fi

if [[ $DO_COMPILE == 1 ]]; then
	rm -rf $OUT_DIR
	mkdir $OUT_DIR
	emcc $WANDER_SRC_DIR/*.c  --preload-file $WANDER_SRC_DIR/a3.misc --preload-file $WANDER_SRC_DIR/a3.wrld -w -o $WANDER_OUT
fi

ln -sf $(pwd)/src/* bin


