// Wander runs as an ordinary terminal program: it reads commands from stdin a
// line at a time and writes to stdout. Rather than fake that with a textarea,
// we give it a real terminal (xterm.js) behind a real pty (xterm-pty), which
// supplies the line discipline the program expects -- canonical-mode line
// editing, echo, and the control characters (^C, ^D, ^U, ^W).
//
// The one thing a browser can't do is let the program *block* on a read, so the
// wasm module is built with -sASYNCIFY and xterm-pty pauses it while it waits
// for a line of input. See the "Terminal" section of the README.

const term = new Terminal({
  cursorBlink: true,
  fontFamily: "'Lucida Console', Monaco, monospace",
  fontSize: 15,
  scrollback: 5000,
  theme: {
    background: '#000000',
    foreground: '#ffffff',
  },
});

const fitAddon = new FitAddon.FitAddon();
term.loadAddon(fitAddon);
term.open(document.getElementById('terminal'));
fitAddon.fit();
window.addEventListener('resize', () => fitAddon.fit());
term.focus();

// master talks to the terminal, slave talks to the program.
const { master, slave } = openpty();
term.loadAddon(master);

slave.write('Loading Wander...\n');

var Module = {
  // Picked up by xterm-pty's emscripten-pty.js, which patches the Emscripten
  // runtime so the program's stdin/stdout/ioctl go to this pty.
  pty: slave,
  onExit: (status) => {
    slave.write(`\n[wander exited (${status}); reload to play again]\n`);
  },
};

const script = document.createElement('script');
script.src = 'wander.js';
document.body.appendChild(script);
