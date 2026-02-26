//
//  DebugFloatingButton.swift
//  DebugTool-iOS
//
//  Created by qiyongkaka on 2026/2/28.
//

import UIKit

final class DebugFloatingButton: UIView {
    private let label = UILabel()
    private(set) var isUserDragging = false
    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)
        layer.cornerRadius = 22
        layer.masksToBounds = true

        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "DBG"
        label.textColor = .white
        label.font = .systemFont(ofSize: 13, weight: .bold)
        addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(pan)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func handleTap() {
        onTap?()
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let superview else { return }
        let translation = gesture.translation(in: superview)
        center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
        gesture.setTranslation(.zero, in: superview)

        if gesture.state == .began {
            isUserDragging = true
        }

        if gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed {
            isUserDragging = false
            snapToEdge(in: superview)
        }
    }

    private func snapToEdge(in superview: UIView) {
        let insets = superview.safeAreaInsets
        let minX = insets.left + bounds.width / 2 + 8
        let maxX = superview.bounds.width - insets.right - bounds.width / 2 - 8
        let minY = insets.top + bounds.height / 2 + 8
        let maxY = superview.bounds.height - insets.bottom - bounds.height / 2 - 8

        let targetX = center.x <= superview.bounds.midX ? minX : maxX
        let targetY = min(max(center.y, minY), maxY)

        UIView.animate(withDuration: 0.2) {
            self.center = CGPoint(x: targetX, y: targetY)
        }
    }
}
