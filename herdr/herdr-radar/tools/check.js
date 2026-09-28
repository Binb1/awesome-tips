#!/usr/bin/env node
'use strict';

// `npm run check`: the declaration files agree with lib/identity.js, and every
// script parses. No test runner needed for a zero-dependency plugin.

const { execFileSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const problems = require('../lib/identity').verify(root);
for (const dir of ['bin', 'lib']) {
  for (const file of fs.readdirSync(path.join(root, dir))) {
    if (!file.endsWith('.js')) continue;
    try {
      execFileSync(process.execPath, ['--check', path.join(root, dir, file)], { stdio: 'pipe' });
    } catch (error) {
      problems.push(`${dir}/${file}: ${String(error.stderr).trim().split('\n')[0]}`);
    }
  }
}
// The tab-bar block's poll interval has to stay above its timeout. Inverted, a
// slow tick is still running when the next one starts, and on Windows every tick
// is a fresh `cmd.exe`: the overlap compounds until the machine stops
// responding. That happened. It is two numbers on one generated line — exactly
// the pair that drifts — so read them back out of the text that gets written.
const tabBar = require('../lib/managed-config').block();
const timings = /interval_seconds = (\d+), timeout_seconds = (\d+)/.exec(tabBar);
if (!timings) {
  problems.push('tab-bar block: no longer states an interval and a timeout');
} else if (Number(timings[1]) <= Number(timings[2])) {
  problems.push(
    `tab-bar block: interval_seconds (${timings[1]}) must be greater than timeout_seconds ` +
      `(${timings[2]}); overlapping ticks pile up processes`,
  );
}

// Nothing we write into a terminal's config may set that terminal's primary
// font. Our font holds icons and nothing else, so claiming the primary slot
// sends every ordinary character to a font that cannot draw it and the terminal
// falls back to something the user never picked. Ghostty's `font-family` and
// kitty's `font_family` both do exactly that; only the per-codepoint
// redirections belong in the block. Reported in #4.
const claimsPrimaryFont = /^\s*(font-family|font_family)[\s=]/;
for (const terminal of require('../lib/font').TERMINALS) {
  const line = terminal.lines.find((text) => claimsPrimaryFont.test(text));
  if (line) {
    problems.push(
      `${terminal.name} block: sets the terminal's primary font (${line.trim()}); ` +
        'map our codepoints instead, our font has only icons',
    );
  }
}

if (problems.length) {
  console.error(problems.join('\n'));
  process.exit(1);
}
console.log('ok');
