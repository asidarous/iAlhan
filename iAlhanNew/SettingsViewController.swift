import UIKit

@MainActor
final class SettingsViewController: UITableViewController {
    private let textSizeControl = UISegmentedControl(
        items: HymnTextSize.allCases.map(\.title)
    )
    private let previewLabel = UILabel()
    private let headerView = UIView()
    private let headerTitleLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        AppAppearance.configureNavigationBar(for: self)
        tableView.backgroundColor = AppAppearance.creamColor
        AppAppearance.configureTable(tableView)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
        configureHeader()
        configureTextSizeControl()
        configurePreview()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let targetWidth = tableView.bounds.width
        if headerView.frame.width != targetWidth {
            headerView.frame = CGRect(x: 0, y: 0, width: targetWidth, height: 60)
            tableView.tableHeaderView = headerView
        }
    }

    private func configureHeader() {
        headerView.backgroundColor = GlobalConstants.kColor_DarkColor

        headerTitleLabel.text = "Settings"
        headerTitleLabel.textColor = GlobalConstants.kColor_GoldColor
        headerTitleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        headerTitleLabel.adjustsFontForContentSizeCategory = true
        headerTitleLabel.textAlignment = .center
        headerTitleLabel.accessibilityTraits = .header
        headerTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(headerTitleLabel)

        NSLayoutConstraint.activate([
            headerTitleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            headerTitleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            headerTitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: headerView.leadingAnchor, constant: 20),
            headerTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: headerView.trailingAnchor, constant: -20)
        ])

        headerView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 60)
        tableView.tableHeaderView = headerView
    }

    private func configureTextSizeControl() {
        textSizeControl.selectedSegmentIndex = ReadingPreferences.hymnTextSize.rawValue
        textSizeControl.selectedSegmentTintColor = GlobalConstants.kColor_DarkColor
        textSizeControl.setTitleTextAttributes(
            [.foregroundColor: GlobalConstants.kColor_DarkColor],
            for: .normal
        )
        textSizeControl.setTitleTextAttributes(
            [.foregroundColor: UIColor.white],
            for: .selected
        )
        textSizeControl.addTarget(
            self,
            action: #selector(textSizeChanged),
            for: .valueChanged
        )
        textSizeControl.accessibilityLabel = "Hymn text size"
    }

    private func configurePreview() {
        previewLabel.text = "Ⲡⲓϩⲱⲥ · Hymn text preview"
        previewLabel.numberOfLines = 0
        previewLabel.textAlignment = .center
        previewLabel.textColor = GlobalConstants.kColor_DarkColor
        previewLabel.adjustsFontForContentSizeCategory = true
        previewLabel.backgroundColor = AppAppearance.cellCreamColor
        previewLabel.layer.cornerRadius = 16
        previewLabel.layer.cornerCurve = .continuous
        previewLabel.clipsToBounds = true
        updatePreview()
    }

    private func updatePreview() {
        let baseFont = AppAppearance.copticBaseFont(ofSize: 21)
        previewLabel.font = ReadingPreferences.scaledFont(
            baseFont: baseFont,
            relativeTo: .body,
            compatibleWith: traitCollection
        )
    }

    @objc private func textSizeChanged() {
        guard let size = HymnTextSize(rawValue: textSizeControl.selectedSegmentIndex) else {
            return
        }
        ReadingPreferences.hymnTextSize = size
        updatePreview()
        UIAccessibility.post(notification: .announcement, argument: "\(size.title) hymn text")
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    override func tableView(
        _ tableView: UITableView,
        titleForHeaderInSection section: Int
    ) -> String? {
        section == 0 ? "Reading" : "About"
    }

    override func tableView(
        _ tableView: UITableView,
        titleForFooterInSection section: Int
    ) -> String? {
        section == 0
            ? "This adjusts hymn text in addition to your device’s Dynamic Type setting."
            : nil
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.backgroundColor = AppAppearance.cellCreamColor
            cell.selectionStyle = .none

            let titleLabel = UILabel()
            titleLabel.text = "Hymn text size"
            titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
            titleLabel.adjustsFontForContentSizeCategory = true
            titleLabel.textColor = GlobalConstants.kColor_DarkColor

            let stack = UIStackView(arrangedSubviews: [
                titleLabel,
                textSizeControl,
                previewLabel
            ])
            stack.translatesAutoresizingMaskIntoConstraints = false
            stack.axis = .vertical
            stack.spacing = 16
            cell.contentView.addSubview(stack)

            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
                stack.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
                stack.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 16),
                stack.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -16),
                previewLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 72)
            ])
            return cell
        }

        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.backgroundColor = AppAppearance.cellCreamColor
        cell.imageView?.image = UIImage(systemName: "info.circle")
        cell.imageView?.tintColor = GlobalConstants.kColor_DarkColor
        cell.textLabel?.text = "About iAlhan"
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.textLabel?.textColor = GlobalConstants.kColor_DarkColor
        cell.detailTextLabel?.text = "Coptic hymns for every season"
        cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
        cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
        cell.detailTextLabel?.textColor = GlobalConstants.kColor_DarkColor.withAlphaComponent(0.72)
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(
        _ tableView: UITableView,
        willDisplayHeaderView view: UIView,
        forSection section: Int
    ) {
        (view as? UITableViewHeaderFooterView)?.textLabel?.textColor =
            GlobalConstants.kColor_DarkColor.withAlphaComponent(0.78)
    }

    override func tableView(
        _ tableView: UITableView,
        willDisplayFooterView view: UIView,
        forSection section: Int
    ) {
        (view as? UITableViewHeaderFooterView)?.textLabel?.textColor =
            GlobalConstants.kColor_DarkColor.withAlphaComponent(0.72)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }
        tableView.deselectRow(at: indexPath, animated: true)

        let aboutController = AboutViewController()
        navigationController?.pushViewController(aboutController, animated: true)
    }
}

@MainActor
private final class AboutViewController: UIViewController {
    private let headerView = UIView()
    private let headerTitleLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "About iAlhan"
        AppAppearance.configureCreamBackground(for: view)
        AppAppearance.configureNavigationBar(for: self)
        configureHeader()

        let icon = UIImageView(image: UIImage(systemName: "music.note.house.fill"))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.tintColor = GlobalConstants.kColor_DarkColor
        icon.contentMode = .scaleAspectFit
        icon.isAccessibilityElement = false

        let titleLabel = UILabel()
        titleLabel.text = "iAlhan"
        titleLabel.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center
        titleLabel.textColor = GlobalConstants.kColor_DarkColor

        let versionLabel = UILabel()
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        versionLabel.text = appVersion.map { "Version \($0)" }
        versionLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        versionLabel.adjustsFontForContentSizeCategory = true
        versionLabel.textAlignment = .center
        versionLabel.textColor = GlobalConstants.kColor_DarkColor.withAlphaComponent(0.6)

        let bodyLabel = UILabel()
        bodyLabel.text = "In an effort to preserve the great heritage of the Coptic Hymns, this application has been developed to aid deacons and Coptic music enthusiasts explore and learn new hymns. The application will contain major Coptic events. The data will get updated periodically without the need to update the application."
        bodyLabel.font = UIFont.preferredFont(forTextStyle: .body)
        bodyLabel.adjustsFontForContentSizeCategory = true
        bodyLabel.numberOfLines = 0
        bodyLabel.textAlignment = .center
        bodyLabel.textColor = GlobalConstants.kColor_DarkColor.withAlphaComponent(0.72)

        let contactButton = UIButton(type: .system)
        contactButton.setTitle("Contact Us", for: .normal)
        AppAppearance.configurePrimaryButton(contactButton)
        contactButton.addTarget(self, action: #selector(contactUsTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [icon, titleLabel, versionLabel, bodyLabel, contactButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 16
        stack.setCustomSpacing(24, after: bodyLabel)
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -32),
            stack.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 40),
            icon.heightAnchor.constraint(equalToConstant: 72)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func configureHeader() {
        headerView.backgroundColor = GlobalConstants.kColor_DarkColor
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        headerTitleLabel.text = "About iAlhan"
        headerTitleLabel.textColor = GlobalConstants.kColor_GoldColor
        headerTitleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        headerTitleLabel.adjustsFontForContentSizeCategory = true
        headerTitleLabel.textAlignment = .center
        headerTitleLabel.accessibilityTraits = .header
        headerTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(headerTitleLabel)


        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            headerTitleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            headerTitleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            headerTitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: headerView.leadingAnchor, constant: 20),
            headerTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: headerView.trailingAnchor, constant: -20)
        ])
    }


    @objc private func contactUsTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let contactController = storyboard.instantiateViewController(
            withIdentifier: "ContactViewController"
        )
        present(UINavigationController(rootViewController: contactController), animated: true)
    }
}
