//
//  DebugPanelViewController.swift
//  DebugTool-iOS
//
//  Created by qiyongkaka on 2026/2/27.
//

import UIKit

final class DebugPanelViewController: UIViewController {
    private enum Item {
        case performanceHud
    }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let items: [Item] = [.performanceHud]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Debug Panel"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(handleClose)
        )

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SwitchCell.self, forCellReuseIdentifier: SwitchCell.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func handleClose() {
        dismiss(animated: true)
    }

    private func updateHud(isOn: Bool) {
        if isOn {
            if let window = currentKeyWindow() {
                PerformanceHUD.shared.start(in: window)
            } else {
                reloadHudSwitch(isOn: false)
            }
        } else {
            PerformanceHUD.shared.stop()
        }
    }

    private func reloadHudSwitch(isOn: Bool) {
        if let index = items.firstIndex(where: { $0 == .performanceHud }) {
            let indexPath = IndexPath(row: index, section: 0)
            if let cell = tableView.cellForRow(at: indexPath) as? SwitchCell {
                cell.setSwitch(isOn: isOn)
            }
        }
    }

    private func currentKeyWindow() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.flatMap(\.windows).first { $0.isKeyWindow } ?? scenes.flatMap(\.windows).first
    }
}

extension DebugPanelViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SwitchCell.reuseIdentifier, for: indexPath)
        guard let switchCell = cell as? SwitchCell else { return cell }
        let item = items[indexPath.row]
        switch item {
        case .performanceHud:
            switchCell.configure(title: "Performance HUD", isOn: PerformanceHUD.shared.isRunning)
            switchCell.onToggle = { [weak self] isOn in
                self?.updateHud(isOn: isOn)
            }
        }
        return switchCell
    }
}

extension DebugPanelViewController: UITableViewDelegate {}

private final class SwitchCell: UITableViewCell {
    static let reuseIdentifier = "SwitchCell"

    private let titleLabel = UILabel()
    private let toggleSwitch = UISwitch()

    var onToggle: ((Bool) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        toggleSwitch.translatesAutoresizingMaskIntoConstraints = false
        toggleSwitch.addTarget(self, action: #selector(handleToggle), for: .valueChanged)

        contentView.addSubview(titleLabel)
        contentView.addSubview(toggleSwitch)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            toggleSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            toggleSwitch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: toggleSwitch.leadingAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func configure(title: String, isOn: Bool) {
        titleLabel.text = title
        toggleSwitch.isOn = isOn
    }

    func setSwitch(isOn: Bool) {
        toggleSwitch.isOn = isOn
    }

    @objc private func handleToggle() {
        onToggle?(toggleSwitch.isOn)
    }
}
