import UIKit

final class EditorController {
    weak var textView: UITextView?

    private(set) var selectionAnchor: Int = 0
    private var preferredColumnX: CGFloat?
    private var trackpadAccX: CGFloat = 0
    private var trackpadAccY: CGFloat = 0
    private var lastWordHapticAt = Date.distantPast

    private var nsText: NSString {
        (textView?.text ?? "") as NSString
    }

    private var settings: EditorSettings { EditorSettings.shared }

    func syncAnchorFromSelection() {
        guard let tv = textView else { return }
        let range = tv.selectedRange
        if range.length == 0 {
            selectionAnchor = range.location
        } else if selectionAnchor != range.location && selectionAnchor != NSMaxRange(range) {
            selectionAnchor = range.location
        }
    }

    func rememberAnchorForSelection() {
        guard let tv = textView else { return }
        let range = tv.selectedRange
        if range.length == 0 {
            selectionAnchor = range.location
        }
    }

    func moveLeft(extending: Bool = false) {
        EditorLog.event("MOVE_LEFT")
        moveByCharacters(-1, extending: extending)
    }

    func moveRight(extending: Bool = false) {
        EditorLog.event("MOVE_RIGHT")
        moveByCharacters(1, extending: extending)
    }

    func moveWordLeft(extending: Bool = false) {
        EditorLog.event("MOVE_WORD_LEFT")
        moveToWord(forward: false, extending: extending)
        hapticWord()
    }

    func moveWordRight(extending: Bool = false) {
        EditorLog.event("MOVE_WORD_RIGHT")
        moveToWord(forward: true, extending: extending)
        hapticWord()
    }

    func moveUp(extending: Bool = false) {
        EditorLog.event("MOVE_UP")
        moveVertically(-1, extending: extending)
    }

    func moveDown(extending: Bool = false) {
        EditorLog.event("MOVE_DOWN")
        moveVertically(1, extending: extending)
    }

    func moveLineStart(extending: Bool = false) {
        EditorLog.event("MOVE_LINE_START")
        guard textView != nil else { return }
        let text = nsText
        let origin = originIndex(extending: extending, towardStart: true)
        let line = text.lineRange(for: NSRange(location: min(origin, max(text.length, 0)), length: 0))
        let lineBody = text.substring(with: line) as NSString
        let firstCode = line.location + TextOperations.firstNonWhitespaceOffset(in: lineBody)
        let target = (origin == firstCode) ? line.location : firstCode
        setFreeEnd(target, extending: extending)
        clearPreferredColumn()
    }

    func moveLineEnd(extending: Bool = false) {
        EditorLog.event("MOVE_LINE_END")
        guard textView != nil else { return }
        let text = nsText
        let origin = originIndex(extending: extending, towardStart: false)
        let line = text.lineRange(for: NSRange(location: min(origin, max(text.length, 0)), length: 0))
        var end = NSMaxRange(line)
        if end > line.location {
            let last = text.character(at: end - 1)
            if last == 10 || last == 13 { end -= 1 }
        }
        setFreeEnd(end, extending: extending)
        clearPreferredColumn()
    }

    func pageUp(extending: Bool = false) {
        moveVertically(-pageLineCount(), extending: extending)
    }

    func pageDown(extending: Bool = false) {
        moveVertically(pageLineCount(), extending: extending)
    }

    func indent() {
        EditorLog.event("INDENT")
        guard let tv = textView else { return }
        let mutation = TextOperations.indent(
            text: nsText,
            selectedRange: tv.selectedRange,
            indentString: settings.indentString
        )
        apply(mutation)
    }

    func outdent() {
        EditorLog.event("OUTDENT")
        guard let tv = textView else { return }
        let mutation = TextOperations.outdent(
            text: nsText,
            selectedRange: tv.selectedRange,
            indentString: settings.indentString,
            indentWidth: settings.indentWidth
        )
        apply(mutation)
    }

    func insertPair(open: String, close: String) {
        EditorLog.event("INSERT_PAIR", "\(open)\(close)")
        guard let tv = textView else { return }
        let range = tv.selectedRange
        let selected = nsText.substring(with: range)
        let mutation: TextMutation
        if range.length > 0 {
            mutation = TextOperations.wrapPair(open: open, close: close, selected: selected, range: range)
        } else {
            mutation = TextOperations.insertEmptyPair(open: open, close: close, at: range.location)
        }
        apply(mutation)
    }

    func insertText(_ string: String) {
        textView?.insertText(string)
        clearPreferredColumn()
    }

    func handleReturn() -> Bool {
        guard let tv = textView else { return false }
        let mutation = TextOperations.smartReturn(
            text: nsText,
            selectedRange: tv.selectedRange,
            indentString: settings.indentString
        )
        apply(mutation)
        return true
    }

    func skipCloserIfNeeded(_ typed: String) -> Bool {
        guard let tv = textView else { return false }
        guard TextOperations.shouldSkipCloser(typed, at: tv.selectedRange, in: nsText) else {
            return false
        }
        setFreeEnd(tv.selectedRange.location + 1, extending: false)
        return true
    }

    func selectCurrentLine() {
        guard let tv = textView else { return }
        let line = TextOperations.lineRange(intersecting: tv.selectedRange, in: nsText)
        tv.selectedRange = line
        selectionAnchor = line.location
        tv.scrollRangeToVisible(line)
    }

    func selectLineRange(from startLine: Int, to endLine: Int) {
        guard let tv = textView else { return }
        let text = nsText
        let a = min(startLine, endLine)
        let b = max(startLine, endLine)
        var location = 0
        var current = 1
        var start = 0
        var end = text.length
        while location <= text.length {
            let line = text.lineRange(for: NSRange(location: min(location, text.length), length: 0))
            if current == a { start = line.location }
            if current == b { end = NSMaxRange(line) }
            if current >= b { break }
            if NSMaxRange(line) >= text.length { break }
            location = NSMaxRange(line)
            current += 1
        }
        let range = NSRange(location: start, length: max(0, end - start))
        tv.selectedRange = range
        selectionAnchor = start
        tv.scrollRangeToVisible(range)
    }

    func expandSelection() {
        guard let tv = textView else { return }
        let next = TextOperations.expandSelection(text: nsText, selectedRange: tv.selectedRange)
        tv.selectedRange = next
        selectionAnchor = next.location
        tv.scrollRangeToVisible(next)
    }

    func undo() {
        EditorLog.event("UNDO")
        textView?.undoManager?.undo()
    }

    func redo() {
        EditorLog.event("REDO")
        textView?.undoManager?.redo()
    }

    func copy() {
        textView?.copy(nil)
    }

    func cut() {
        textView?.cut(nil)
    }

    func paste() {
        textView?.paste(nil)
    }

    func selectAll() {
        textView?.selectAll(nil)
    }

    func find(query: String, forward: Bool) {
        guard let tv = textView, !query.isEmpty else { return }
        let text = nsText
        let current = tv.selectedRange
        let found: NSRange
        if forward {
            let start = min(NSMaxRange(current), text.length)
            var range = text.range(of: query, options: .literal, range: NSRange(location: start, length: text.length - start))
            if range.location == NSNotFound {
                range = text.range(of: query, options: .literal, range: NSRange(location: 0, length: start))
            }
            found = range
        } else {
            let prefixLen = current.location
            var range = text.range(
                of: query,
                options: [.literal, .backwards],
                range: NSRange(location: 0, length: prefixLen)
            )
            if range.location == NSNotFound {
                range = text.range(
                    of: query,
                    options: [.literal, .backwards],
                    range: NSRange(location: 0, length: text.length)
                )
            }
            found = range
        }
        if found.location != NSNotFound {
            tv.selectedRange = found
            selectionAnchor = found.location
            tv.scrollRangeToVisible(found)
        }
    }

    func trackpadBegan() {
        trackpadAccX = 0
        trackpadAccY = 0
        EditorLog.event("CURSOR_DRAG", "begin")
    }

    func trackpadChanged(dx: CGFloat, dy: CGFloat, velocity: CGPoint, extending: Bool) {
        trackpadAccX += dx
        trackpadAccY += dy
        let h = CGFloat(settings.horizontalThreshold)
        let v = CGFloat(settings.verticalThreshold)
        guard h > 0, v > 0 else { return }

        var step = 1
        var wordMode = false
        if settings.accelerationEnabled {
            let speed = hypot(velocity.x, velocity.y)
            if speed >= settings.fastVelocity {
                wordMode = true
            } else if speed >= settings.mediumVelocity {
                step = 2
            }
        }

        if wordMode {
            while trackpadAccX >= h {
                moveWordRight(extending: extending)
                trackpadAccX -= h
            }
            while trackpadAccX <= -h {
                moveWordLeft(extending: extending)
                trackpadAccX += h
            }
        } else {
            while trackpadAccX >= h {
                for _ in 0..<step { moveByCharacters(1, extending: extending) }
                trackpadAccX -= h
            }
            while trackpadAccX <= -h {
                for _ in 0..<step { moveByCharacters(-1, extending: extending) }
                trackpadAccX += h
            }
        }

        while trackpadAccY >= v {
            moveVertically(1, extending: extending)
            trackpadAccY -= v
        }
        while trackpadAccY <= -v {
            moveVertically(-1, extending: extending)
            trackpadAccY += v
        }
    }

    func trackpadEnded() {
        trackpadAccX = 0
        trackpadAccY = 0
        EditorLog.event("CURSOR_DRAG", "end")
    }

    func clearPreferredColumn() {
        preferredColumnX = nil
    }

    private func moveByCharacters(_ delta: Int, extending: Bool) {
        guard let tv = textView else { return }
        if !extending, tv.selectedRange.length > 0 {
            let edge = delta < 0 ? tv.selectedRange.location : NSMaxRange(tv.selectedRange)
            setFreeEnd(edge, extending: false)
            return
        }
        let origin = originIndex(extending: extending, towardStart: delta < 0)
        setFreeEnd(origin + delta, extending: extending)
        clearPreferredColumn()
    }

    private func moveToWord(forward: Bool, extending: Bool) {
        guard let tv = textView else { return }
        if !extending, tv.selectedRange.length > 0 {
            let edge = forward ? NSMaxRange(tv.selectedRange) : tv.selectedRange.location
            setFreeEnd(edge, extending: false)
            return
        }
        let origin = originIndex(extending: extending, towardStart: !forward)
        let next = TextOperations.wordBoundary(in: nsText, from: origin, forward: forward)
        setFreeEnd(next, extending: extending)
        clearPreferredColumn()
    }

    private func moveVertically(_ lines: Int, extending: Bool) {
        guard let tv = textView else { return }
        if !extending, tv.selectedRange.length > 0 {
            let edge = lines < 0 ? tv.selectedRange.location : NSMaxRange(tv.selectedRange)
            setFreeEnd(edge, extending: false)
        }
        guard let range = tv.selectedTextRange else { return }
        let movingFrom: UITextPosition
        if extending {
            let origin = originIndex(extending: true, towardStart: lines < 0)
            movingFrom = tv.position(from: tv.beginningOfDocument, offset: origin) ?? range.start
        } else {
            movingFrom = range.start
        }
        let caret = tv.caretRect(for: movingFrom)
        if preferredColumnX == nil {
            preferredColumnX = caret.midX
        }
        let lineHeight = max(tv.font?.lineHeight ?? 20, max(caret.height, 1))
        let point = CGPoint(x: preferredColumnX ?? caret.midX, y: caret.midY + CGFloat(lines) * lineHeight)
        if let pos = tv.closestPosition(to: point) {
            let offset = tv.offset(from: tv.beginningOfDocument, to: pos)
            setFreeEnd(offset, extending: extending)
        }
    }

    private func originIndex(extending: Bool, towardStart: Bool) -> Int {
        guard let tv = textView else { return 0 }
        let range = tv.selectedRange
        if range.length == 0 { return range.location }
        if extending {
            if selectionAnchor == range.location { return NSMaxRange(range) }
            if selectionAnchor == NSMaxRange(range) { return range.location }
            return towardStart ? range.location : NSMaxRange(range)
        }
        return towardStart ? range.location : NSMaxRange(range)
    }

    private func setFreeEnd(_ raw: Int, extending: Bool) {
        guard let tv = textView else { return }
        let maxLen = nsText.length
        let index = min(max(raw, 0), maxLen)
        if extending {
            let start = min(selectionAnchor, index)
            let end = max(selectionAnchor, index)
            tv.selectedRange = NSRange(location: start, length: end - start)
            tv.scrollRangeToVisible(NSRange(location: index, length: 0))
        } else {
            selectionAnchor = index
            tv.selectedRange = NSRange(location: index, length: 0)
            tv.scrollRangeToVisible(NSRange(location: index, length: 0))
        }
    }

    private func apply(_ mutation: TextMutation) {
        guard let tv = textView else { return }
        guard let start = tv.position(from: tv.beginningOfDocument, offset: mutation.replacementRange.location),
              let end = tv.position(from: start, offset: mutation.replacementRange.length),
              let uiRange = tv.textRange(from: start, to: end) else { return }
        tv.undoManager?.beginUndoGrouping()
        tv.replace(uiRange, withText: mutation.replacement)
        tv.selectedRange = mutation.selectedRange
        selectionAnchor = mutation.selectedRange.location
        tv.undoManager?.endUndoGrouping()
        clearPreferredColumn()
        tv.scrollRangeToVisible(mutation.selectedRange)
    }

    private func pageLineCount() -> Int {
        guard let tv = textView else { return 10 }
        let height = tv.bounds.height - tv.adjustedContentInset.top - tv.adjustedContentInset.bottom
        let line = tv.font?.lineHeight ?? 20
        return max(1, Int(height / line) - 1)
    }

    private func hapticWord() {
        let now = Date()
        if now.timeIntervalSince(lastWordHapticAt) > 0.08 {
            EditorHaptics.wordBoundary()
            lastWordHapticAt = now
        }
    }
}
