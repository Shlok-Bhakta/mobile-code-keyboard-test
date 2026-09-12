import UIKit

final class SymbolPickerView: UIView {
    static let rows: [[String]] = [
        ["!", "@", "#", "$", "%", "^", "&", "*", "|", "~", "?"],
        ["(", ")", "{", "}", "[", "]", "<", ">", "/", "\\"],
        ["=", "+", "-", "_", ".", ",", ":", ";", "`", "'", "\""],
    ]

    var onHover: ((String?) -> Void)?
    var onPick: ((String) -> Void)?

    private(set) var selected: String?
    private var tiles: [Tile] = []
    private var focus: Int?
    private let gap: CGFloat = 3

    private struct Tile {
        let symbol: String
        let view: UIView
        let label: UILabel
        var rest: CGRect = .zero
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = false
        isMultipleTouchEnabled = true

        for row in Self.rows {
            for symbol in row {
                let view = UIView()
                view.layer.cornerRadius = 8
                view.clipsToBounds = true
                let label = UILabel()
                label.text = symbol
                label.textAlignment = .center
                label.adjustsFontSizeToFitWidth = true
                label.minimumScaleFactor = 0.5
                label.font = UIFont.monospacedSystemFont(ofSize: 16, weight: .medium)
                label.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(label)
                NSLayoutConstraint.activate([
                    label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                    label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 1),
                    label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -1),
                ])
                view.isUserInteractionEnabled = true
                let tap = UITapGestureRecognizer(target: self, action: #selector(tappedTile(_:)))
                view.addGestureRecognizer(tap)
                addSubview(view)
                tiles.append(Tile(symbol: symbol, view: view, label: label))
            }
        }
        paint()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        computeRest()
        applyFisheye(animated: false)
    }

    func hover(at point: CGPoint) {
        let next = index(near: point)
        guard next != focus else { return }
        focus = next
        selected = next.map { tiles[$0].symbol }
        applyFisheye(animated: true)
        paint()
        if next != nil { EditorHaptics.hoverTick() }
        onHover?(selected)
    }

    func clearHover() {
        guard focus != nil || selected != nil else { return }
        focus = nil
        selected = nil
        applyFisheye(animated: true)
        paint()
        onHover?(nil)
    }

    func commit() -> String? {
        selected
    }

    @objc private func tappedTile(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view,
              let tile = tiles.first(where: { $0.view === view })
        else { return }
        onPick?(tile.symbol)
    }

    private func computeRest() {
        let grid = bounds.insetBy(dx: 1, dy: 1)
        guard grid.width > 8, grid.height > 8 else { return }
        let rowCount = CGFloat(Self.rows.count)
        let rowH = (grid.height - gap * (rowCount - 1)) / rowCount
        var i = 0
        for (r, row) in Self.rows.enumerated() {
            let n = CGFloat(row.count)
            let colW = (grid.width - gap * (n - 1)) / n
            let y = grid.minY + CGFloat(r) * (rowH + gap)
            for c in 0..<row.count {
                tiles[i].rest = CGRect(
                    x: grid.minX + CGFloat(c) * (colW + gap),
                    y: y,
                    width: colW,
                    height: rowH
                )
                i += 1
            }
        }
    }

    private func index(near point: CGPoint) -> Int? {
        let slop = bounds.insetBy(dx: -10, dy: -10)
        guard slop.contains(point), !tiles.isEmpty else { return nil }
        var best = 0
        var bestDist = CGFloat.greatestFiniteMagnitude
        for (i, tile) in tiles.enumerated() {
            let d = hypot(point.x - tile.rest.midX, point.y - tile.rest.midY)
            if d < bestDist {
                bestDist = d
                best = i
            }
        }
        return best
    }

    private func applyFisheye(animated: Bool) {
        let changes = {
            for (i, tile) in self.tiles.enumerated() {
                let frame = self.visualFrame(for: i)
                tile.view.frame = frame
                tile.view.layer.zPosition = (i == self.focus) ? 10 : 1
                let focused = i == self.focus
                tile.label.font = UIFont.monospacedSystemFont(
                    ofSize: focused ? 28 : max(13, min(18, frame.height * 0.42)),
                    weight: focused ? .bold : .medium
                )
            }
        }
        if animated {
            UIView.animate(
                withDuration: 0.18,
                delay: 0,
                usingSpringWithDamping: 0.78,
                initialSpringVelocity: 0.6,
                options: [.allowUserInteraction, .beginFromCurrentState],
                animations: changes
            )
        } else {
            changes()
        }
    }

    private func visualFrame(for index: Int) -> CGRect {
        let rest = tiles[index].rest.insetBy(dx: 0.5, dy: 0.5)
        guard let focus, tiles.indices.contains(focus) else { return rest }
        let origin = tiles[focus].rest
        let dx = rest.midX - origin.midX
        let dy = rest.midY - origin.midY
        let dist = hypot(dx, dy)
        if index == focus {
            let growX = min(22, rest.width * 0.7)
            let growY = min(18, rest.height * 0.55)
            return rest.insetBy(dx: -growX * 0.5, dy: -growY * 0.5)
        }
        let sigma: CGFloat = 56
        let pull = exp(-(dist * dist) / (2 * sigma * sigma))
        let shrink = 1 - 0.22 * pull
        let nx = dist > 0.5 ? dx / dist : 0
        let ny = dist > 0.5 ? dy / dist : 0
        let push = 14 * pull
        let w = rest.width * shrink
        let h = rest.height * shrink
        return CGRect(
            x: rest.midX - w * 0.5 + nx * push,
            y: rest.midY - h * 0.5 + ny * push,
            width: w,
            height: h
        )
    }

    private func paint() {
        for (i, tile) in tiles.enumerated() {
            if i == focus {
                tile.view.backgroundColor = .systemPurple
                tile.label.textColor = .white
            } else {
                tile.view.backgroundColor = UIColor.tertiarySystemFill
                tile.label.textColor = .label
            }
        }
    }
}
