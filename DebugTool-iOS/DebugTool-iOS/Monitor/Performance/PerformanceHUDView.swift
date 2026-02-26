//
//  PerformanceHUDView.swift
//  DebugTool-iOS
//
//  Created by qiyongkaka on 2026/2/26.
//

import UIKit

final class PerformanceHUDView: UIView {

    private let label = UILabel()
    private(set) var isUserDragging = false

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.black.withAlphaComponent(0.7)
        layer.cornerRadius = 8
        layer.masksToBounds = true

        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.systemGreen
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 3
        label.text = "FPS --"
        addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        addGestureRecognizer(pan)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(fps: Double, cpu: Double, memoryMB: Double, memoryPercent: Double) {
        label.text = String(format: "FPS %.0f\nCPU %.0f%%\nMEM %.0f MB (%.1f%%)", fps, cpu, memoryMB, memoryPercent)
        let fpsSeverity = severityLevel(
            good: fps >= 55,
            warn: fps >= 45
        )
        let cpuSeverity = severityLevel(
            good: cpu < 60,
            warn: cpu < 85
        )
        let memorySeverity = severityLevel(
            good: memoryPercent < 50,
            warn: memoryPercent < 75
        )
        label.textColor = color(for: max(fpsSeverity, cpuSeverity, memorySeverity))
    }

    private func severityLevel(good: Bool, warn: Bool) -> Int {
        if good { return 0 }
        if warn { return 1 }
        return 2
    }

    private func color(for severity: Int) -> UIColor {
        switch severity {
        case 0:
            return .systemGreen
        case 1:
            return .systemYellow
        default:
            return .systemRed
        }
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
            clampToSuperview()
        }
    }

    private func clampToSuperview() {
        guard let superview else { return }

        let insets = superview.safeAreaInsets
        let minX = insets.left + bounds.width / 2 + 8
        let maxX = superview.bounds.width - insets.right - bounds.width / 2 - 8
        let minY = insets.top + bounds.height / 2 + 8
        let maxY = superview.bounds.height - insets.bottom - bounds.height / 2 - 8

        let clampedX = min(max(center.x, minX), maxX)
        let clampedY = min(max(center.y, minY), maxY)
        center = CGPoint(x: clampedX, y: clampedY)
    }
}
