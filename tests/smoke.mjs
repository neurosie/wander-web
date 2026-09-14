// Loads the built page in a real browser and plays a couple of moves. This
// exercises the parts that only exist once everything is wired together: the
// wasm module, ASYNCIFY suspending it on a blocking read, and the xterm-pty
// line discipline delivering a typed line to stdin.
//
// Run after ./build.sh:  node tests/smoke.mjs

import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { extname } from 'node:path';
import { chromium } from '@playwright/test';

const ROOT = new URL('../bin/', import.meta.url);
const CONTENT_TYPES = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.wasm': 'application/wasm',
};

const server = createServer(async (req, res) => {
  const path = decodeURIComponent(req.url.split('?')[0]);
  const file = new URL('.' + (path === '/' ? '/index.html' : path), ROOT);
  if (!file.pathname.startsWith(ROOT.pathname)) {
    res.writeHead(403).end();
    return;
  }
  try {
    const body = await readFile(file);
    res.writeHead(200, {
      'Content-Type': CONTENT_TYPES[extname(file.pathname)] ?? 'application/octet-stream',
    });
    res.end(body);
  } catch {
    res.writeHead(404).end('not found');
  }
});
await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
const base = `http://127.0.0.1:${server.address().port}`;

// Read the whole terminal, scrollback included -- the intro text is longer
// than one screen, so the visible rows aren't enough.
const readTerminal = () => {
  const buffer = term.buffer.active;
  let text = '';
  for (let i = 0; i < buffer.length; i++) {
    text += buffer.getLine(i).translateToString(true) + '\n';
  }
  return text;
};

// CHROMIUM_PATH lets you point at a system Chromium instead of Playwright's.
const browser = await chromium.launch(
  process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {},
);
const page = await browser.newPage({ viewport: { width: 1100, height: 700 } });

const pageErrors = [];
page.on('pageerror', (e) => pageErrors.push(String(e)));

const screen = () => page.evaluate(readTerminal);
const expect = async (what, text, timeout = 60000) => {
  try {
    await page.waitForFunction(
      ([read, t]) => new Function('return ' + read)()().includes(t),
      [readTerminal.toString(), text],
      { timeout, polling: 200 },
    );
    console.log(`PASS  ${what}`);
  } catch {
    console.error(`FAIL  ${what}: never saw ${JSON.stringify(text)}`);
    console.error('\n--- terminal ---\n' + (await screen()));
    console.error('\n--- page errors ---\n' + (pageErrors.join('\n') || 'none'));
    await browser.close();
    server.close();
    process.exit(1);
  }
};

const send = async (line) => {
  await page.locator('.xterm-helper-textarea').focus();
  await page.keyboard.type(line);
  await page.keyboard.press('Enter');
};

await page.goto(base);

// The module loaded, ran, and printed the opening room through the pty.
await expect('game starts and prints the first room', 'Aldebaran III spaceport');
await expect('objdesc() renders the object in the room', 'There is a credit card here.');

// A typed line reaches stdin, which means ASYNCIFY resumed the module.
await send('take card');
await expect('typed command reaches stdin', 'Done');
await send('balance');
await expect('game keeps accepting commands', 'Your account holds');

// exit(0) unwinds cleanly under ASYNCIFY.
await send('quit');
await expect('quit exits cleanly', 'wander exited (0)');

if (pageErrors.length) {
  console.error('FAIL  page reported errors:\n' + pageErrors.join('\n'));
  await browser.close();
  server.close();
  process.exit(1);
}

console.log('\nAll checks passed.');
await browser.close();
server.close();
