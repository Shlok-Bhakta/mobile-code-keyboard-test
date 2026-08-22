# Experiments

Places this prototype departed from the packet, and things to watch on device.

## Accessory height is fixed

Reloading `inputAccessoryView` while a finger is down on NAV drops the touch and can bounce the keyboard. All three layers share one 176 pt accessory. TYPE has empty space. That is deliberate so hold modes never resize the keyboard.

## NAV + trackpad selects by default

The packet's ideal grammar is NAV + SELECT + drag. Three fingers on a phone accessory is miserable. Default is:

- NAV held + drag CURSOR = extend selection
- SELECT + arrow keys = extend selection
- SELECT + drag also selects

Turn `NAV + trackpad selects` off in Tune if you want SELECT required for the trackpad.

## SELECT sits where SYM was

During NAV the right-hand SYM key becomes SELECT. Left thumb stays on NAV, right thumb hits SELECT or the movement cluster. SYM is unreachable until NAV is released. Fine for v0.

## HOME toggles

First press goes to the first non-whitespace character. Press again at that spot and you get column 0. Matches a lot of desktop editors and was cheaper than adding a second button.

## Word movement is code-ish, not UIKit's tokenizer

`UITextInputTokenizer` treated `_` and some punctuation as I did not want. Movement uses alnum+underscore vs whitespace vs other. Later this should be syntax tokens.

## TextKit 1

`UITextView` is created with a classic `NSLayoutManager` so the gutter can enumerate line fragments. TextKit 2 would have meant a custom renderer or guessing.

## Long lines

No wrap by default. Container width is a fixed 8000 pt rather than measuring every line. Wrap is a Tune toggle if that feels worse than wrapping.

## Pair skip is naive

Typing a closer while the next character is the same closer jumps over it, whether we inserted that closer or not. Good enough. Do not expect language-aware matching.

## Smart Return is brace heuristics

Only `{ } ( ) [ ]` plus "keep this line's indent". Python `:` does not extra-indent. Markdown is just preserved indent.

## EXPAND is parser-free

Word, line, blank-line block, document. Not the `foo.bar(baz + quux)` ladder from the packet. No Tree-sitter.

## Outdent has three bindings

Swipe-left on TAB was requested. Long-press TAB and a `⇤` button are backups so the indent experiment is not blocked if swipe is flaky. Question 10 in the packet is still the one to answer.

## Haptics

Fire on entering NAV/SYM, starting SELECT, and word-boundary jumps. Not on every character. Kill them in Tune if they buzz too much.

## Momentary vs toggle

Default is hold-to-use. Tune can switch NAV or SYM to toggle if UIKit eats the touch-up. Backgrounding, keyboard hide, and touch cancel all force TYPE.

## Find steals the keyboard

The find field is a normal `UITextField`, so the accessory goes away while you search. Acceptable for v0.

## Unsigned IPA

The Xcode project builds with signing disabled so you can sign on device. That is why there is no team or provisioning file here.
