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
        case battery
        case stallMonitor
        case lastStall
    }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let sections: [[Item]] = [
        [.performanceHud, .battery],
        [.stallMonitor, .lastStall]
    ]
    private var batteryStatusText = "Unknown"
    private var lastStallText = "None"

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
        tableView.register(ValueCell.self, forCellReuseIdentifier: ValueCell.reuseIdentifier)
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        BatteryMonitor.shared.onUpdate = { [weak self] text in
            self?.batteryStatusText = text
            self?.reloadBatteryCell()
        }
        BatteryMonitor.shared.start()
        batteryStatusText = BatteryMonitor.shared.statusText()

        MainThreadStallMonitor.shared.onStall = { [weak self] event in
            self?.lastStallText = String(format: "%.0fms", event.duration * 1000)
            self?.reloadLastStallCell()
        }
        lastStallText = MainThreadStallMonitor.shared.latestEvent.map { String(format: "%.0fms", $0.duration * 1000) } ?? "None"
        tableView.reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        BatteryMonitor.shared.onUpdate = nil
        BatteryMonitor.shared.stop()
        MainThreadStallMonitor.shared.onStall = nil
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
        if let indexPath = indexPath(for: .performanceHud),
           let cell = tableView.cellForRow(at: indexPath) as? SwitchCell {
            cell.setSwitch(isOn: isOn)
        }
    }

    private func reloadBatteryCell() {
        if let indexPath = indexPath(for: .battery),
           let cell = tableView.cellForRow(at: indexPath) as? ValueCell {
            cell.configure(title: "Battery Drain", value: batteryStatusText)
        }
    }

    private func updateStallMonitor(isOn: Bool) {
        if isOn {
            MainThreadStallMonitor.shared.start()
        } else {
            MainThreadStallMonitor.shared.stop()
        }
    }

    private func reloadStallSwitch() {
        if let indexPath = indexPath(for: .stallMonitor),
           let cell = tableView.cellForRow(at: indexPath) as? SwitchCell {
            cell.setSwitch(isOn: MainThreadStallMonitor.shared.isRunning)
        }
    }

    private func reloadLastStallCell() {
        if let indexPath = indexPath(for: .lastStall),
           let cell = tableView.cellForRow(at: indexPath) as? ValueCell {
            cell.configure(title: "Last Stall", value: lastStallText)
        }
    }

    private func indexPath(for item: Item) -> IndexPath? {
        for (sectionIndex, items) in sections.enumerated() {
            if let rowIndex = items.firstIndex(where: { $0 == item }) {
                return IndexPath(row: rowIndex, section: sectionIndex)
            }
        }
        return nil
    }

    private func currentKeyWindow() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.flatMap(\.windows).first { $0.isKeyWindow } ?? scenes.flatMap(\.windows).first
    }
}

extension DebugPanelViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section][indexPath.row]
        switch item {
        case .performanceHud:
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchCell.reuseIdentifier, for: indexPath)
            guard let switchCell = cell as? SwitchCell else { return cell }
            switchCell.configure(title: "Performance HUD", isOn: PerformanceHUD.shared.isRunning)
            switchCell.onToggle = { [weak self] isOn in
                self?.updateHud(isOn: isOn)
            }
            return switchCell
        case .battery:
            return configuredBatteryCell(tableView, indexPath: indexPath)
        case .stallMonitor:
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchCell.reuseIdentifier, for: indexPath)
            guard let switchCell = cell as? SwitchCell else { return cell }
            switchCell.configure(title: "Main Thread Stall", isOn: MainThreadStallMonitor.shared.isRunning)
            switchCell.onToggle = { [weak self] isOn in
                self?.updateStallMonitor(isOn: isOn)
            }
            return switchCell
        case .lastStall:
            return configuredLastStallCell(tableView, indexPath: indexPath)
        }
    }

    private func configuredBatteryCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ValueCell.reuseIdentifier, for: indexPath)
        guard let valueCell = cell as? ValueCell else { return cell }
        valueCell.configure(title: "Battery Drain", value: batteryStatusText)
        return valueCell
    }

    private func configuredLastStallCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ValueCell.reuseIdentifier, for: indexPath)
        guard let valueCell = cell as? ValueCell else { return cell }
        valueCell.configure(title: "Last Stall", value: lastStallText)
        return valueCell
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

private final class ValueCell: UITableViewCell {
    static let reuseIdentifier = "ValueCell"

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        valueLabel.font = .systemFont(ofSize: 14, weight: .regular)
        valueLabel.textColor = .secondaryLabel
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        contentView.addSubview(titleLabel)
        contentView.addSubview(valueLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            valueLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: valueLabel.leadingAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func configure(title: String, value: String) {
        titleLabel.text = title
        valueLabel.text = value
    }
}
