# Experiments

Places this prototype departed from the packet, and things to watch on device.

## Switchable keyboard trials

The blue KEYS button in the top chrome opens five saved switches: larger code keys, compact controls, a fixed 50 pt bar, operator swipes, and Flash jump. All start on. The menu also has presets for all on and the earlier layout. Try the same short Python, TypeScript, and Rust edits with each combination; count correct code characters per second, including correction time.

## Flash jump

Tap JUMP in the top bar and type text that appears on screen. Matches light up in purple, with orange letter labels. Type a label to move the caret straight to that match, or keep typing to narrow the search. A unique match jumps automatically after two search characters. Return picks the nearest match; the small X or Escape cancels. This uses the existing top bar and system keyboard, so it adds no permanent height.

The search covers the visible code area. Matching is case insensitive and supports overlapping text. Labels avoid characters that would continue a match, so typing more search text remains possible. The current caret is excluded. For a larger file, scroll near the destination first.

Compact controls reduce the NAV pad from 96 to 78 pt and the SYM key from 56 to 48 pt. This frees width for the code keys but makes the NAV hold area smaller. The fixed-height SYM row exposes seven common symbols; Apple's `123` page handles the rest. These two reach and target-size tradeoffs need on-device thumb testing.

## Nested NAV / SELECT pad

One finger, two zones. Hold the pad for NAV icons. Orange square in the bottom-left corner selects. Once you are in select, the square and its hit region grow so a small drift does not drop you back to move. The old CURSOR bar and the pad trackpad are gone. Hold space on Apple's keyboard when you want a trackpad.

The original pad is 96 pt and the bar springs to 108 pt while NAV is held. With compact controls and the fixed-height experiment on, the pad is 78 pt and the bar remains 50 pt. Centered select was too easy to miss and too easy to leave.

## Native keyboard

A custom letter grid saved vertical space and fought UIKit. Apple's QWERTY is back. Autocap, autocorrect, smart quotes, and inline prediction stay off.

## Accessory height

TYPE stays 50 pt. The fixed-height experiment keeps NAV and SYM at 50 pt too. Turning it off restores NAV at 108 pt and SYM at 122 pt.

## Symbol slide

Hold `#`, slide onto the grid, release to insert. The key under the thumb grows and pushes neighbors, like the Apple Watch keyboard. `#` shows the hovered glyph. Hit testing uses the resting grid so the map does not crawl under your finger.

## Icons, no labels

Pair glyphs stay as `()` because those are the icons. Everything else is SF Symbols.

## Page up/down

Hold the compact NAV up/down keys for a page move. The original expanded NAV grid has no page keys; Apple's spacebar trackpad is another way to move freely.

## HOME toggles

First non-whitespace, then column 0.

## Unsigned IPA

The Xcode project builds with signing disabled so you can sign on device.

## Remote run

Run posts the buffer to Compiler Explorer's execution API (pinned: `python313`, `r1980`). Piston was the first pick but its public instance went whitelist-only in early 2026; Wandbox's sandbox was erroring the same week. TypeScript has no working free runner (Godbolt's TS is a native compiler without console), so the TS sample is highlighting-only and Run says so instead of failing. Needs network; offline gives a clean error, not a hang.

## Regex highlighting

Keywords, strings, comments, numbers, plus per-language types and builtins, computed off-main and applied as attribute-only edits with undo registration off. Stale passes (typed during the 0.35 s debounce) are dropped by comparing against a snapshot. Rust lifetimes are deliberately uncolored: a loose single-quote pattern would eat code up to the next apostrophe.
