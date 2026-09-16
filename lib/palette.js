'use strict';

// One source of truth for every colour this project puts on screen: the few
// Herdr chrome tokens we override, and the sidebar tokens we publish. Keeping
// them in one file is the point — a theme picked in Herdr and a sidebar
// coloured by hand drift apart, and the seam shows.
//
// Herdr has no theme-file format: a built-in is chosen by name, and
// `[theme.custom]` overrides tokens on top of it (`resolve_palette_for_theme_name`
// does `Palette::from_name(name).with_overrides(custom)`). Third-party themes
// use the same table — the marketplace's herdr-theme-picker writes it too.
//
// Which is exactly why this file overrides as LITTLE as possible. Copying a
// whole built-in palette in here would pin every colour: switching themes in
// Herdr's settings would change nothing, and `auto_switch` could no longer
// repaint for a light or dark host, because `[theme.custom]` is one static
// table applied to whichever theme is live. Override one token and the rest of
// the theme still works.

// The only chrome token we take over, and why:
//
// A built-in's `active_row_bg` is often a grey a shade off `panel_bg`, so the
// current Space and the focused Agent read as unselected (Tokyo Night Day's
// #d2d3da against its #e1e2e7 panel is the case that prompted this). These are
// that theme family's own selection blue, pushed to where it works as a row
// fill.
//
// Two variants because one value cannot serve both: a fill has to sit darker
// than a light panel and lighter than a dark one, and the row's text colour
// does not change with it. `bin/configure.js` picks the variant from the
// configured theme name and leaves the block out entirely under `auto_switch`,
// where neither value would be right half the time.
const chrome = {
  light: { active_row_bg: '#b9cdf2' },
  dark: { active_row_bg: '#414868' },
};

// Light built-ins, for that choice. Everything else in Herdr's THEME_NAMES is
// dark; `terminal` follows the host's own colours and counts as neither.
const lightThemes = [
  'catppuccin-latte',
  'tokyo-night-day',
  'gruvbox-light',
  'one-light',
  'solarized-light',
  'kanagawa-lotus',
  'rose-pine-dawn',
];

// Vendor colours, shown while an agent works. Shape already carries the state
// (§2.1), which frees colour to say whose agent it is. Sidebar token colours
// are static hex and cannot follow the theme (quirks §1), so every value here
// is chosen to read on both light and dark panels.
// Vendor hues — every one of them the vendor's own, checked against the mark
// the company publishes. Invented colours used to live here and no longer do:
// a brand that signs itself in black has no hue to carry, and painting one on
// says something about the row that is not true.
//
// A vendor absent from this table gets NO colour. The logo cell leaves its own
// `fg` unset, Herdr preserves the contextual default for any style field left
// out, and the mark inherits the row's ink — black on a light terminal, white
// on a dark one. That is the faithful reading of a monochrome brand, and the
// only treatment here that follows the theme, since these values are static
// hex and cannot (quirks §1).
//
// Two constraints shape the values:
//
//   - Both grounds at once. A hex that reads on white and dies on a dark panel
//     is half a colour. Everything here clears 3:1 against both, which is why
//     Cline (#323b43, near-black) and Kilo (#f8f676, pale yellow) are carried
//     at their own hue with a moved lightness rather than as published.
//   - Green and red stay out: they mean done and blocked, and a vendor wearing
//     either reads as a state.
//
// Gemini, Kimi and DeepSeek all sign in blue and land within 13° of one
// another. Nothing to be done about that without dropping a published hue —
// the glyphs separate those rows, and colour only groups them coarsely.
const brand = {
  claude: '#d97757', // Anthropic coral, as published
  gemini: '#4285f4', // the blue out of Google's four
  kimi: '#1783ff', // as published
  deepseek: '#4d6bfe', // as published
  qwen: '#615ced', // as published
  kiro: '#9046ff', // as published
  cline: '#586876', // #323b43 lightened: as published it dies on a dark panel
  kilo: '#9a9808', // #f8f676 darkened: as published it dies on a light one
  other: '#c78a1f', // a recognised harness with no hue of its own
};

// The vendors with a colour of their own, in table order. The Agents row
// colours a logo by rule and the Spaces row gives each of these a token, so
// both lists have to name the same vendors or a mark is coloured in one panel
// and grey in the other — which is how Antigravity and Kiro ended up branded
// beside their titles and anonymous in Spaces.
const brandVendors = Object.keys(brand).filter((vendor) => vendor !== 'other');

// The ink a hueless mark is drawn in: black on a light panel, white on a dark
// one, which is how a monochrome brand signs itself.
//
// This used to be done by leaving the cell's `fg` out and letting Herdr keep
// the contextual default. That reads well as a sentence and rendered as a
// muted grey — the sidebar's default ink is second-rank text, not the ink a
// logo wants, and it left the black-signing brands looking switched off beside
// the coloured ones. Naming the value is the only way to get the two ends of
// the scale, and the sidebar block is rebuilt per appearance anyway
// (`sidebarBlock(variant)`), so a static hex here still follows the desktop.
const inks = {
  light: '#16161c',
  dark: '#e9e9f0',
};

function inkFor(variant) {
  return inks[variant] ?? inks.light;
}

// State colours. Green and red are semantic and outrank branding: they exist
// to pull the eye. Idle recedes so a glance separates busy from parked.
const state = {
  done: '#4c9a5a',
  blocked: '#c04a4a',
  idle: '#6e738d',
  unknown: '#907aa9',
  none: '#9a9eb3', // a Space with no live agent: a dot, so names stay aligned
  subtle: '#7c7f93', // titles and other second-rank text
};

// The freshness scale, and colour is its entire signal — the three tiers draw
// the same mark (lib/logos.js).
//
// The middle tier is plain text on purpose. It was amber for a while, chosen
// to make the scale read as a cooling gradient (warm, cooling, cold), and the
// metaphor was fine but the arithmetic was not: most sessions are in the
// middle most of the time, so the amber was not a signal, it was the
// background — a high-attention colour applied to "nothing in particular",
// competing with the green it was supposed to defer to. A scale over a list
// only needs to mark the DEVIATIONS: worked in the last hours stands out,
// untouched since yesterday recedes, and everything between is what ordinary
// looks like.
//
// It flips with the panel, because receding means light-on-light but
// dark-on-dark — a single static hex cannot fade on both (quirks §1). The
// faded end must also actually fade: its first value was a light *blue*
// (#b3b6c4), which over a warm translucent panel read as tinted text, a
// highlight rather than an absence. Stale keeps almost no chroma.
//
// `idleNormal` is deliberately separate from `state.idle`: the Spaces list
// paints its own idle mark with the latter, and "this workspace has nothing
// running" is not a point on the freshness scale.
//
// An entry is one row now — `logo · title` — so these three ARE the entry's
// text colour, not a decoration beside it. That raises the bar: a tier has to
// stay readable as a whole sentence, not just legible as a mark.
const stateByVariant = {
  light: {
    idleFresh: '#416c4f',
    idleNormal: '#6b6259',
    idleStale: '#a4a5a9',
  },
  dark: {
    idleFresh: '#95bba2',
    idleNormal: '#a99e92',
    idleStale: '#585a64',
  },
};

// The state colours for one appearance. Everything outside the freshness
// scale reads acceptably on either side and stays shared.
function stateFor(variant) {
  return { ...state, ...(stateByVariant[variant] ?? stateByVariant.light) };
}

module.exports = { chrome, lightThemes, brand, brandVendors, inkFor, state, stateFor };
