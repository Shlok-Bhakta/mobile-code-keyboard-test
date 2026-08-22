import Foundation

struct TextMutation {
    var replacementRange: NSRange
    var replacement: String
    var selectedRange: NSRange
}

enum TextOperations {
    static let closers: Set<Character> = [")", "}", "]", "\"", "'", "`"]

    static func utf16Length(_ string: String) -> Int {
        (string as NSString).length
    }

    static func lineRange(intersecting range: NSRange, in text: NSString) -> NSRange {
        guard text.length > 0 else { return NSRange(location: 0, length: 0) }

        let start = text.lineRange(for: NSRange(location: min(range.location, text.length), length: 0))

        var endIndex = min(NSMaxRange(range), text.length)
        if range.length > 0, endIndex > 0 {
            let last = text.character(at: endIndex - 1)
            if last == 10 || last == 13 {
                endIndex -= 1
            }
        }
        endIndex = min(max(endIndex, 0), max(text.length - 1, 0))
        let end = text.lineRange(for: NSRange(location: endIndex, length: 0))
        let location = start.location
        return NSRange(location: location, length: NSMaxRange(end) - location)
    }

    static func indentPrefix(of line: String) -> String {
        String(line.prefix { $0 == " " || $0 == "\t" })
    }

    static func firstNonWhitespaceOffset(in line: NSString) -> Int {
        var i = 0
        while i < line.length {
            let c = line.character(at: i)
            if c != 32 && c != 9 { break }
            i += 1
        }
        return i
    }

    static func indent(
        text: NSString,
        selectedRange: NSRange,
        indentString: String
    ) -> TextMutation {
        let block = lineRange(intersecting: selectedRange, in: text)
        let blockString = text.substring(with: block)
        let lines = splitKeepingNewlines(blockString)
        let indented = lines.map { line -> String in
            if line.isEmpty || line == "\n" || line == "\r\n" { return line }
            return indentString + line
        }.joined()

        let extraPerLine = utf16Length(indentString)
        let lineCount = max(1, lines.filter { !$0.isEmpty && $0 != "\n" && $0 != "\r\n" }.count)
        let extraTotal = extraPerLine * lineCount

        var newSelection = selectedRange
        if selectedRange.length == 0 {
            newSelection = NSRange(location: selectedRange.location + extraPerLine, length: 0)
        } else {
            newSelection = NSRange(
                location: selectedRange.location + extraPerLine,
                length: selectedRange.length + extraTotal - extraPerLine
            )
        }

        return TextMutation(replacementRange: block, replacement: indented, selectedRange: newSelection)
    }

    static func outdent(
        text: NSString,
        selectedRange: NSRange,
        indentString: String,
        indentWidth: Int
    ) -> TextMutation {
        let block = lineRange(intersecting: selectedRange, in: text)
        let blockString = text.substring(with: block)
        let lines = splitKeepingNewlines(blockString)
        var removedBeforeCaret = 0
        var removedInSelection = 0
        var cursor = block.location
        let caret = selectedRange.location
        let selEnd = NSMaxRange(selectedRange)

        let outdented = lines.map { line -> String in
            let stripped = stripIndent(line, indentString: indentString, indentWidth: indentWidth)
            let removed = utf16Length(line) - utf16Length(stripped)
            let lineStart = cursor
            let lineEnd = cursor + utf16Length(line)
            if caret >= lineStart && caret <= lineEnd {
                removedBeforeCaret += min(removed, max(0, caret - lineStart))
            } else if lineEnd <= caret {
                removedBeforeCaret += removed
            }
            if selectedRange.length > 0 {
                let overlapStart = max(lineStart, caret)
                let overlapEnd = min(lineEnd, selEnd)
                if overlapEnd > overlapStart {
                    removedInSelection += min(removed, overlapEnd - overlapStart)
                }
            }
            cursor = lineEnd
            return stripped
        }.joined()

        let newSelection: NSRange
        if selectedRange.length == 0 {
            newSelection = NSRange(location: max(block.location, caret - removedBeforeCaret), length: 0)
        } else {
            let newStart = max(block.location, caret - removedBeforeCaret)
            let newLen = max(0, selectedRange.length - removedInSelection)
            newSelection = NSRange(location: newStart, length: newLen)
        }

        return TextMutation(replacementRange: block, replacement: outdented, selectedRange: newSelection)
    }

    static func wrapPair(open: String, close: String, selected: String, range: NSRange) -> TextMutation {
        let replacement = open + selected + close
        let inner = NSRange(location: range.location + utf16Length(open), length: range.length)
        return TextMutation(replacementRange: range, replacement: replacement, selectedRange: inner)
    }

    static func insertEmptyPair(open: String, close: String, at location: Int) -> TextMutation {
        let replacement = open + close
        return TextMutation(
            replacementRange: NSRange(location: location, length: 0),
            replacement: replacement,
            selectedRange: NSRange(location: location + utf16Length(open), length: 0)
        )
    }

    static func shouldSkipCloser(_ typed: String, at range: NSRange, in text: NSString) -> Bool {
        guard range.length == 0, typed.count == 1, let char = typed.first, closers.contains(char) else {
            return false
        }
        guard range.location < text.length else { return false }
        let next = text.substring(with: NSRange(location: range.location, length: 1))
        return next == typed
    }

    static func smartReturn(text: NSString, selectedRange: NSRange, indentString: String) -> TextMutation {
        let line = text.lineRange(for: NSRange(location: min(selectedRange.location, text.length), length: 0))
        let lineText = text.substring(with: line) as NSString
        let indentLen = firstNonWhitespaceOffset(in: lineText)
        let indent = lineText.substring(to: indentLen)

        let beforeLen = max(0, selectedRange.location - line.location)
        let before = lineText.substring(to: min(beforeLen, lineText.length))
        let afterStart = min(beforeLen + selectedRange.length, lineText.length)
        var after = lineText.substring(from: afterStart)
        if after.hasSuffix("\n") { after = String(after.dropLast()) }
        if after.hasSuffix("\r") { after = String(after.dropLast()) }

        let trimmedBefore = before.trimmingCharacters(in: .whitespaces)
        let trimmedAfter = after.trimmingCharacters(in: .whitespaces)

        let pairs: [(Character, Character)] = [("{", "}"), ("(", ")"), ("[", "]")]
        var splitPair = false
        if let last = trimmedBefore.last {
            for (open, close) in pairs where last == open && trimmedAfter.first == close {
                splitPair = true
                break
            }
        }

        let replacement: String
        let caret: Int
        if splitPair {
            replacement = "\n" + indent + indentString + "\n" + indent
            caret = selectedRange.location + 1 + utf16Length(indent) + utf16Length(indentString)
        } else if trimmedBefore.hasSuffix("{") || trimmedBefore.hasSuffix("(") || trimmedBefore.hasSuffix("[") {
            replacement = "\n" + indent + indentString
            caret = selectedRange.location + 1 + utf16Length(indent) + utf16Length(indentString)
        } else {
            replacement = "\n" + indent
            caret = selectedRange.location + 1 + utf16Length(indent)
        }

        return TextMutation(
            replacementRange: selectedRange,
            replacement: replacement,
            selectedRange: NSRange(location: caret, length: 0)
        )
    }

    static func wordBoundary(in text: NSString, from index: Int, forward: Bool) -> Int {
        let len = text.length
        var i = min(max(index, 0), len)
        if forward {
            if i >= len { return len }
            let startClass = charClass(text.character(at: i))
            while i < len && charClass(text.character(at: i)) == startClass {
                i += 1
            }
            if startClass != .whitespace {
                while i < len && charClass(text.character(at: i)) == .whitespace {
                    i += 1
                }
            }
            return i
        } else {
            if i <= 0 { return 0 }
            i -= 1
            let startClass = charClass(text.character(at: i))
            while i > 0 && charClass(text.character(at: i - 1)) == startClass {
                i -= 1
            }
            if startClass == .whitespace && i > 0 {
                let inner = charClass(text.character(at: i - 1))
                while i > 0 && charClass(text.character(at: i - 1)) == inner {
                    i -= 1
                }
            }
            return i
        }
    }

    static func expandSelection(text: NSString, selectedRange: NSRange) -> NSRange {
        let len = text.length
        guard len > 0 else { return selectedRange }

        if selectedRange.length == 0 {
            return wordRange(containing: selectedRange.location, in: text)
        }

        let line = lineRange(intersecting: selectedRange, in: text)
        if selectedRange.location > line.location || NSMaxRange(selectedRange) < NSMaxRange(line) {
            return line
        }

        let block = paragraphRange(containing: selectedRange, in: text)
        if selectedRange.location > block.location || NSMaxRange(selectedRange) < NSMaxRange(block) {
            return block
        }

        return NSRange(location: 0, length: len)
    }

    static func wordRange(containing location: Int, in text: NSString) -> NSRange {
        guard text.length > 0 else { return NSRange(location: 0, length: 0) }
        var i = min(location, text.length - 1)
        if location >= text.length { i = text.length - 1 }
        if charClass(text.character(at: i)) != .word, i > 0, charClass(text.character(at: i - 1)) == .word {
            i -= 1
        }
        if charClass(text.character(at: i)) != .word {
            return NSRange(location: location, length: 0)
        }
        var start = i
        var end = i + 1
        while start > 0 && charClass(text.character(at: start - 1)) == .word { start -= 1 }
        while end < text.length && charClass(text.character(at: end)) == .word { end += 1 }
        return NSRange(location: start, length: end - start)
    }

    static func paragraphRange(containing range: NSRange, in text: NSString) -> NSRange {
        guard text.length > 0 else { return range }
        var start = min(range.location, text.length)
        var end = min(NSMaxRange(range), text.length)

        while start > 0 {
            if text.character(at: start - 1) == 10 {
                var look = start
                var blank = true
                while look < text.length && text.character(at: look) != 10 {
                    if text.character(at: look) != 32 && text.character(at: look) != 9 {
                        blank = false
                        break
                    }
                    look += 1
                }
                if blank { break }
            }
            start -= 1
        }

        while end < text.length {
            if text.character(at: end) == 10 {
                var look = end + 1
                var blank = true
                while look < text.length && text.character(at: look) != 10 {
                    if text.character(at: look) != 32 && text.character(at: look) != 9 {
                        blank = false
                        break
                    }
                    look += 1
                }
                if blank {
                    end += 1
                    break
                }
            }
            end += 1
        }
        return NSRange(location: start, length: end - start)
    }

    private enum CharClass { case word, whitespace, other }

    private static func charClass(_ c: unichar) -> CharClass {
        if c == 95 { return .word }
        if CharacterSet.alphanumerics.contains(Unicode.Scalar(c) ?? Unicode.Scalar(32)!) { return .word }
        if c == 32 || c == 9 || c == 10 || c == 13 { return .whitespace }
        return .other
    }

    private static func splitKeepingNewlines(_ string: String) -> [String] {
        var lines: [String] = []
        var current = ""
        for ch in string {
            current.append(ch)
            if ch == "\n" {
                lines.append(current)
                current = ""
            }
        }
        if !current.isEmpty { lines.append(current) }
        if string.isEmpty { lines = [""] }
        return lines
    }

    private static func stripIndent(_ line: String, indentString: String, indentWidth: Int) -> String {
        if line.isEmpty { return line }
        var body = line
        var newline = ""
        if body.hasSuffix("\r\n") {
            newline = "\r\n"
            body = String(body.dropLast(2))
        } else if body.hasSuffix("\n") {
            newline = "\n"
            body = String(body.dropLast())
        }

        if body.hasPrefix(indentString) {
            return String(body.dropFirst(indentString.count)) + newline
        }
        if body.hasPrefix("\t") {
            return String(body.dropFirst()) + newline
        }
        var removed = 0
        var idx = body.startIndex
        while removed < indentWidth, idx < body.endIndex, body[idx] == " " {
            idx = body.index(after: idx)
            removed += 1
        }
        return String(body[idx...]) + newline
    }
}
