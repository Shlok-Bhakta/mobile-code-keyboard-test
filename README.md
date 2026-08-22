# Mobile Editor

Phone-native code editing prototype. System keyboard stays. Custom controls above it do the work Apple's text interactions do poorly: punctuation, caret movement, selection, indent.

Not an IDE. No git, files, LSP, or cloud. Open it and type.

## Open in Xcode

`MobileEditor.xcodeproj`. Scheme `MobileEditor`. iPhone, iOS 17+.

Unsigned device builds are already configured (`CODE_SIGNING_ALLOWED = NO`). Sign on device with Autoloader or your own cert.

On-device install (Autoloader signs locally):

- Open this on the phone: https://planista.shloklab.us/V18z7j-tDCOX_Td4
- Or: `autoloader://install?url=https%3A%2F%2Fplanista.shloklab.us%2F3MDZUgfn-6bKWBi0`
- IPA: https://planista.shloklab.us/3MDZUgfn-6bKWBi0

Local copy: `dist/MobileEditor.ipa`. Rebuild with `xcodebuild` if the links go stale.

Scratch text autosaves to `Documents/scratch.txt` and comes back on next launch.

## Layout

```
MobileEditor/
  MobileEditorApp.swift          SwiftUI shell
  Editor/
    EditorViewController.swift   screen, find bar, mode state
    CodeTextView.swift           UITextView, code typing traits
    EditorController.swift       move / select / indent / pairs
    TextOperations.swift         string-level edits
    EditorSettings.swift         UserDefaults knobs
    DocumentStore.swift          scratch file
    InputMode.swift
    EditorHaptics.swift
    EditorLog.swift
  Input/
    EditingAccessoryView.swift   TYPE / NAV / SYM surfaces
    HoldButton.swift             momentary NAV / SYM / SELECT
    CursorTrackpadView.swift
  Gutter/LineNumberGutter.swift
  Samples/SampleDocuments.swift
  Settings/DebugSettingsView.swift
```

UI controls call `EditorController`. Don't reach into `UITextView` ranges from buttons.

## Interaction map

The accessory is always above the keyboard. The strip at the top says `TYPE`, `NAV`, `NAV SELECT`, or `SYM`.

**TYPE**

- Type on the system keyboard. Autocorrect, smart quotes, capitalization, and inline prediction are off.
- `TAB` indents 4 spaces. Swipe `TAB` left, long-press it, or tap `⇤` to outdent.
- Pair buttons `() {} [] "" '' ``` insert both sides and leave the caret inside. If text is selected they wrap it.
- Typing a closer sitting on an already-inserted closer jumps over it.
- `=` `;` `.` `,` insert one character.
- `↶` `↷` undo / redo.

**NAV** (hold with left thumb)

- Finger down: navigation layer. Finger up: TYPE again. Nothing stays latched unless you turn off momentary in Tune.
- `← → ↑ ↓` character / line. Vertical tries to keep column.
- `W← W→` word-ish tokens: letters, digits, underscore. Punctuation is its own class.
- `HOME` toggles first non-space vs column 0. `END` is end of line.
- `PG↑ PG↓` jump by a screenful.
- `EXPAND` grows selection: word, line, blank-line block, document. No parser.
- `UNDO REDO COPY CUT PASTE` on the bottom row of the layer.

**SELECT** (hold in NAV, right side)

- Movement extends selection instead of moving a caret.
- Release SELECT: selection stays. Release NAV: back to TYPE, selection stays.

**CURSOR** trackpad

- Drag horizontally: characters. Vertically: lines. Relative to finger motion, not absolute position.
- Defaults: 12 pt / character, 24 pt / line.
- Fast flicks jump by words. Finger up stops immediately.
- Default: while NAV is held, trackpad extends selection (two thumbs, no SELECT). Hold SELECT + drag also selects. Turn `NAV + trackpad selects` off in Tune if that feels wrong.

**SYM** (hold with right thumb)

- Programming symbol pad. Release to return to TYPE.
- Individual keys insert one character. Pair wrapping stays on the TYPE row.

**Gutter**

- Tap a line number: select that line.
- Drag vertically: select a line range.

**Find**

- `Find` in the top bar, or Cmd-F with a hardware keyboard. Next / previous only. No replace.

**Return**

- Keeps the current line's indent.
- `{|}` / `(|)` / `[|]` splits into an indented inner line.

**Hardware keyboard**

- Cmd-Z / Shift-Z, C, X, V, A, F.

## Tune

Top-right `Tune`. Values persist in UserDefaults.

Worth changing on device first:

- Horizontal / vertical trackpad thresholds
- Acceleration and the two velocity cutoffs
- Haptics
- Indent width / tabs
- Line wrap
- NAV/SYM delay (0 = instant hold)
- Momentary vs toggle for NAV and SYM
- `NAV + trackpad selects`

Logs go to the Xcode console: `NAV_DOWN`, `SELECT_DOWN`, `MOVE_RIGHT`, `INDENT`, `CURSOR_DRAG`, and so on.

## Samples

`Samples` menu: Rust, TypeScript, Python, Markdown. Replaces the buffer. Current scratch is what autosaves.

## What is in v0

- Code-configured `UITextView`
- Accessory: indent, pairs, undo, NAV, SELECT, SYM, trackpad
- Smart Return
- Line gutter selection
- Find
- Debug panel
- Light / dark, monospace, almost no chrome

## Rough edges

See `EXPERIMENTS.md`. Short version: accessory is tall, SYM does not replace Apple's QWERTY, word movement is not syntax-aware, and two-thumb holds can still fight UIKit.
