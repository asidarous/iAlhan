//
//  PlayListVC.swift
//  iAlhan
//
//  Created by Sidarous, Arsani on 10/28/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import UIKit

struct PlayHymns {
    var HymnName: String!
    var HymnID: Int!
    var HymnURL: String!
}

private final class DuplicateHymnsAlertViewController: UIViewController {
    var onDismiss: (() -> Void)?
    private let hymnNames: [String]

    init(hymnNames: [String]) {
        self.hymnNames = hymnNames
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        view.accessibilityViewIsModal = true

        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = AppAppearance.cellCreamColor
        card.layer.cornerRadius = 16
        card.layer.cornerCurve = .continuous
        view.addSubview(card)

        let titleLabel = UILabel()
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center
        titleLabel.textColor = GlobalConstants.kColor_DarkColor
        titleLabel.text = hymnNames.count == 1 ? "Hymn Already in Playlist" : "Hymns Already in Playlist"

        let explanationLabel = UILabel()
        explanationLabel.font = UIFont.preferredFont(forTextStyle: .body)
        explanationLabel.adjustsFontForContentSizeCategory = true
        explanationLabel.numberOfLines = 0
        explanationLabel.textAlignment = .center
        explanationLabel.textColor = GlobalConstants.kColor_DarkColor
        explanationLabel.text = hymnNames.count == 1
            ? "This hymn was not added because it already exists in this playlist:"
            : "These hymns were not added because they already exist in this playlist:"

        let hymnNamesView = UITextView()
        hymnNamesView.isEditable = false
        hymnNamesView.isSelectable = false
        hymnNamesView.backgroundColor = .clear
        hymnNamesView.textAlignment = .center
        hymnNamesView.textColor = GlobalConstants.kColor_DarkColor
        hymnNamesView.font = AppAppearance.copticFont(ofSize: 22, relativeTo: .title3)
        hymnNamesView.adjustsFontForContentSizeCategory = true
        hymnNamesView.text = hymnNames.joined(separator: "\n")
        hymnNamesView.accessibilityLabel = hymnNames.joined(separator: ", ")
        hymnNamesView.translatesAutoresizingMaskIntoConstraints = false
        hymnNamesView.heightAnchor.constraint(
            equalToConstant: min(max(CGFloat(hymnNames.count) * 38, 56), 220)
        ).isActive = true

        let okButton = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = "OK"
        configuration.baseBackgroundColor = GlobalConstants.kColor_DarkColor
        configuration.baseForegroundColor = .white
        configuration.cornerStyle = .medium
        okButton.configuration = configuration
        okButton.addTarget(self, action: #selector(dismissAlert), for: .touchUpInside)
        okButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true

        let stack = UIStackView(arrangedSubviews: [titleLabel, explanationLabel, hymnNamesView, okButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            card.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            card.widthAnchor.constraint(lessThanOrEqualToConstant: 420),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)
        ])
    }

    @objc private func dismissAlert() {
        dismiss(animated: true) { [onDismiss] in onDismiss?() }
    }
}

class PlayListVC: UITableViewController {
    @IBOutlet var PlayListItemsTable: UITableView!

    var plArray: [String]!

    var plHymnsArray: [PlayHymns] = []
    var disalert: Bool  = UserDefaults.standard.bool(forKey: "disalert");

    private let headerView = UIView()
    private let headerTitleLabel = UILabel()
    private let addButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Playlists"
        configureNavigationBarAppearance()
        AppAppearance.configureTable(tableView)
        configureHeader()


        NotificationCenter.default.addObserver(self, selector: #selector (loadList(notification:)),name:NSNotification.Name(rawValue: "load"), object: nil)

        plArray = PL_DBManager.shared.getPL()
        updateEmptyState()

        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = true


        if (playlistInstructions == true && !disalert){
            let alert = UIAlertController(title: "Add to playlist", message: "Please select an exiting playlist, or click + to create a new playlist.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            alert.addAction(UIAlertAction(title: "Do Not Show Again", style: UIAlertAction.Style.default, handler: { (action) in
                //execute some code when this option is selected
                UserDefaults.standard.set(true, forKey: "disalert")
                //print("77777777 DISALERT \(UserDefaults.standard.bool(forKey: "disalert"))")
            }))
            self.present(alert, animated: true, completion: nil)
            playlistInstructions = false
        }
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
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

        headerTitleLabel.text = "Playlists"
        headerTitleLabel.textColor = GlobalConstants.kColor_GoldColor
        // Matches the compact, centered inline title used by Season Detail and Hymn
        // Detail (this screen draws its own header instead of a real UINavigationBar,
        // so it needs to match that style explicitly rather than inheriting it).
        headerTitleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        headerTitleLabel.adjustsFontForContentSizeCategory = true
        headerTitleLabel.textAlignment = .center
        headerTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerTitleLabel.accessibilityTraits = .header

        AppAppearance.configureRoundNavigationButton(
            addButton,
            systemImageName: "plus",
            accessibilityLabel: "Create playlist"
        )
        addButton.addTarget(self, action: #selector(addPlaylistTapped), for: .touchUpInside)
        addButton.translatesAutoresizingMaskIntoConstraints = false

        headerView.addSubview(headerTitleLabel)
        headerView.addSubview(addButton)

        // Centered like a real navigation bar's inline title, but allowed to yield that
        // centering (lower priority) rather than collide with the leading edge or the
        // add button if the title ever needs more room than that leaves.
        let centeredTitle = headerTitleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor)
        centeredTitle.priority = .defaultHigh

        NSLayoutConstraint.activate([
            centeredTitle,
            headerTitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: headerView.leadingAnchor, constant: 20),
            headerTitleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            headerTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: addButton.leadingAnchor, constant: -12),

            addButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -12),
            addButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 44),
            addButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        headerView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 60)
        tableView.tableHeaderView = headerView
    }

    @objc private func addPlaylistTapped() {
        performSegue(withIdentifier: "createPLSegue", sender: self)
    }


    private func configureNavigationBarAppearance() {
        AppAppearance.configureNavigationBar(for: self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    @objc func loadList(notification: NSNotification){
        //load data here
        //print("HHHHHHHHERE")
        plArray = PL_DBManager.shared.getPL()
        self.PlayListItemsTable.reloadData()
        updateEmptyState()
    }

    private func updateEmptyState() {
        guard plArray?.isEmpty != false else {
            tableView.backgroundView = nil
            return
        }

        let symbol = UIImageView(image: UIImage(systemName: "music.note.list"))
        symbol.tintColor = GlobalConstants.kColor_DarkColor
        symbol.contentMode = .scaleAspectFit
        symbol.heightAnchor.constraint(equalToConstant: 52).isActive = true
        symbol.isAccessibilityElement = false

        let titleLabel = UILabel()
        titleLabel.text = "No Playlists Yet"
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center
        titleLabel.textColor = GlobalConstants.kColor_DarkColor

        let messageLabel = UILabel()
        messageLabel.text = "Tap + to create a playlist for the hymns you love."
        messageLabel.font = UIFont.preferredFont(forTextStyle: .body)
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [symbol, titleLabel, messageLabel])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 24,
            leading: 32,
            bottom: 24,
            trailing: 32
        )
        stack.isLayoutMarginsRelativeArrangement = true
        tableView.backgroundView = stack
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        var noOfRows = 0
        if (plArray != nil)
        {
            noOfRows = plArray.count
            //print("zzzzzzz count: \(noOfRows)")
            
        }
        
        return noOfRows
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "playlistCell", for: indexPath)
        
        let row = indexPath.row
        
        if (plArray != nil)
        {
            var content = cell.defaultContentConfiguration()
            content.text = plArray?[row]
            content.image = UIImage(systemName: "music.note.list")
            content.imageProperties.tintColor = GlobalConstants.kColor_DarkColor
            content.textProperties.font = UIFont.preferredFont(forTextStyle: .body)
            content.textProperties.color = GlobalConstants.kColor_DarkColor
            content.directionalLayoutMargins = NSDirectionalEdgeInsets(
                top: 10,
                leading: 16,
                bottom: 10,
                trailing: 8
            )
            cell.contentConfiguration = content
        }
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = AppAppearance.cellCreamColor
        cell.contentView.backgroundColor = AppAppearance.cellCreamColor
        
        return cell
    }
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let playlistName = plArray[indexPath.row]

        guard !plHymnsArray.isEmpty else {
            performSegue(withIdentifier: "Show Playlist Detail", sender: playlistName)
            return
        }

        let playlistID = PL_DBManager.shared.getPLID(playlist: playlistName)
        let duplicateHymnNames = PL_DBManager.shared.addHymnsToPL(
            playlist: playlistID,
            hymnLists: plHymnsArray
        )
        plHymnsArray.removeAll()

        if duplicateHymnNames.isEmpty {
            performSegue(withIdentifier: "Show Playlist Detail", sender: playlistName)
        } else {
            showDuplicateHymnsAlert(
                hymnNames: duplicateHymnNames,
                playlistName: playlistName
            )
        }
    }

    private func showDuplicateHymnsAlert(
        hymnNames: [String],
        playlistName: String
    ) {
        let alert = DuplicateHymnsAlertViewController(hymnNames: hymnNames)
        alert.onDismiss = { [weak self] in
            self?.performSegue(
                withIdentifier: "Show Playlist Detail",
                sender: playlistName
            )
        }
        present(alert, animated: true)
    }
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        let row = indexPath.row
        if editingStyle == .delete {
            // Delete the row from the data source
            PL_DBManager.shared.deletePL(playlist: plArray[row])
            plArray.remove(at: row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            updateEmptyState()
            //tableView.
            //self.tableView.reloadData()
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
 

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func viewDidDisappear(_ animated: Bool) {
        plHymnsArray.removeAll()
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let identifier = segue.identifier
        {
            switch identifier
            {
            case "Show Playlist Detail":

                    let playlistDetailVC = segue.destination as! PlaylistDetailVC
                    playlistDetailVC.title = sender as? String
                
                    print ("I'm here")
                
            
            default:
                break
                
                
            }
        }
    }

   
    
}
