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
        hymnNamesView.font = UIFontMetrics(forTextStyle: .title3).scaledFont(
            for: UIFont(name: "COPT", size: 22) ?? UIFont.preferredFont(forTextStyle: .title3)
        )
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBarAppearance()
        AppAppearance.configureTable(tableView)

        
        NotificationCenter.default.addObserver(self, selector: #selector (loadList(notification:)),name:NSNotification.Name(rawValue: "load"), object: nil)
        
        plArray = PL_DBManager.shared.getPL()
        
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
