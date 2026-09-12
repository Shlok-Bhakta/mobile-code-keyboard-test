# Experiments

Places this prototype departed from the packet, and things to watch on device.

## Nested NAV / SELECT pad

One finger, two zones. Hold the pad for NAV icons. Orange square in the bottom-left corner selects. Once you are in select, the square and its hit region grow so a small drift does not drop you back to move. The old CURSOR bar and the pad trackpad are gone. Hold space on Apple's keyboard when you want a trackpad.

The pad is 96 pt and the bar springs to 108 pt while NAV is held. Centered select was too easy to miss and too easy to leave.

## Native keyboard

A custom letter grid saved vertical space and fought UIKit. Apple's QWERTY is back. Autocap, autocorrect, smart quotes, and inline prediction stay off. The accessory bar still expands on NAV/SYM and stays slim while typing.

## Accessory height

TYPE stays 50 pt. NAV springs to 108 pt. SYM springs to 122 pt and hides the NAV pad so the grid can use the width.

## Symbol slide

Hold `#`, slide onto the grid, release to insert. The key under the thumb grows and pushes neighbors, like the Apple Watch keyboard. `#` shows the hovered glyph. Hit testing uses the resting grid so the map does not crawl under your finger.

## Icons, no labels

Pair glyphs stay as `()` because those are the icons. Everything else is SF Symbols.

## Page up/down dropped

Did not fit the compact NAV row. Use the system spacebar trackpad.

## HOME toggles

First non-whitespace, then column 0.

## Unsigned IPA

The Xcode project builds with signing disabled so you can sign on device.
