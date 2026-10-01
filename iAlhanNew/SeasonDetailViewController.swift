//
//  SeasonDetailViewController.swift
//  iAlhanNew
//
//  Created by Sidarous, Arsani on 10/7/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import UIKit

public struct SeasonHymns {
    //var hymnName: String!
    var seasonSections: [String: [EventHymns]]!
}

struct EventHymns {
    var hymnName: String!
    var hymnID: Int!
    var hymnDescription: String!
    var hymnCoptic: String!
    var hymnEnglish: String!
    var hymnAudio: String!
}

class SeasonDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {

    // Model: an album
    //var album: Season?
    //var seasonHymnsStruct: SeasonHymns?
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!

    @IBOutlet var tableView: UITableView!



    let textCellIdentifier = "TextCell"
    var labelText: String?
    
    var eventHymns:[EventHymns]?
    var seasonHymns: [SeasonHymns]?
    
    struct structureArray {
        var sectionName: String!
        var sectionDetails: [AnyObject]!
    }
    
    var objectArray = [structureArray]()

    let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    

   
    func updateUI()
    {
        
        //print (album!.seasonSections?.count)
        
       
        tableView.delegate = self
        tableView.dataSource = self
        
        //print ("Array count \(arrayCount)")
        //print (hymnArray.description)
        
        //print("!!!! SeasonHymns Struct: \(seasonHymns)")
        //print("----------")
        
       
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        AppAppearance.configureCreamBackground(for: view)
        //self.navigationItem.leftBarButtonItem?.tintColor = UIColor.blue
        //UINavigationBar.appearance().tintColor = UIColor.blue
        backgroundImageView?.isHidden = true
        visualEffectView?.effect = nil
        visualEffectView?.backgroundColor = .clear
        AppAppearance.configureTable(tableView)
       
        updateUI()
        
        //print ("Label Text \(labelText)")
        title = labelText
        navigationItem.hidesBackButton = true
        configureNavigationBarAppearance()
        configureAddToPlaylistButton()
    }

    private func configureNavigationBarAppearance() {
        AppAppearance.configureNavigationBar(for: self)
    }

    private func configureAddToPlaylistButton() {
        let addButton = UIButton(type: .system)
        AppAppearance.configureRoundNavigationButton(
            addButton,
            systemImageName: "text.badge.plus",
            accessibilityLabel: "Add season to playlist"
        )
        addButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        addButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        addButton.addTarget(self, action: #selector(AddToPlayList(_:)), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addButton)
    }
    
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        if let row = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: row, animated: true)
        }
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // get rid of the background image from superview
        // backgroundImageView.removeFromSuperview()
        //visualEffectView.removeFromSuperview()

    }
    
 
    
    // MARK:  UITableViewDelegate Methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return (seasonHymns!.count)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rowsPerSection: Int!
        let tempDict = seasonHymns![section].seasonSections
        for (_, v) in tempDict!{
            //print ("k & V: \(k) -- > \(v) ")
            //hymnDetailTemp = v
            //print ("????? No of values for TEMP DICT: \(v.count)")
            rowsPerSection = v.count
        }

        return (rowsPerSection)!
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
   func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        //print ("header for section: \(section)")
    
        let tempDict = seasonHymns![section].seasonSections
    
        let description = tempDict?.keys.first
            //seasonHymns?[section].sectionName.description
    
        //let range = rawDescription.index(rawDescription.startIndex, offsetBy: 4)..<rawDescription.endIndex

        return description
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        let title = UILabel()
        
        title.textColor = GlobalConstants.kColor_DarkColor
        
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor=title.textColor
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextCell", for: indexPath as IndexPath)
        
        let row = indexPath.row
        let section = indexPath.section
        //cell.textLabel?.text = (hymnArray?[row].seasonSections)! as String
        /*print("++++++++++++++++++++")
        print(section)
        print((seasonHymns![section].seasonSections)) */
        let tempDict = seasonHymns![section].seasonSections
        //var hymnDetailTemp
        var hymnNameLabel: String!
        var hymnDescLabel: String!
        var hymnAudioURL: String!
        
        for (_, v) in tempDict!{
            //print ("k & V: \(k) -- > \(v) ")
            //hymnDetailTemp = v
            //print ("Number of hymns in section: \(v.count)")
            //"\u{26AA} \(v[row].hymnName)"
            hymnNameLabel = v[row].hymnName
            hymnDescLabel = v[row].hymnDescription
            hymnAudioURL = v[row].hymnAudio
            //print ("This is the row and hymn name \(row) -->> \(hymnNameLabel)")
            //print(hymnDetailTemp[row].hymnName)
        }
        //cell.textLabel?.text = (objectArray[section].sectionDetails[row].hymnDescription) as String
        let hymnNameFont = AppAppearance.copticFont(ofSize: 20, relativeTo: .headline)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        // Some hymn names are Arabic rather than Coptic text; route through the shared
        // helper so those render with correctly joined Arabic letterforms instead of
        // the Coptic font's disconnected glyphs. This must be the *last* thing set on
        // textLabel: UILabel overwrites attributedText's per-run attributes if `.font`
        // or `.textColor` is assigned afterward, so both are folded in here instead.
        cell.textLabel?.attributedText = AppAppearance.attributedStringHandlingArabic(
            hymnNameLabel,
            baseFont: hymnNameFont,
            extraAttributes: [.foregroundColor: GlobalConstants.kColor_DarkColor]
        )
        cell.detailTextLabel?.text = hymnDescLabel
        cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
        cell.detailTextLabel?.textColor = UIColor(red: 0.24, green: 0.20, blue: 0.16, alpha: 1)
        cell.backgroundColor = AppAppearance.cellCreamColor
        cell.contentView.backgroundColor = AppAppearance.cellCreamColor
        
        let localDir = getDirectory(url: hymnAudioURL)
        let localPath = documentsDirectoryURL.appendingPathComponent(localDir)
        let destinationUrl = localPath.appendingPathComponent((URL(string: hymnAudioURL)?.lastPathComponent)!)
        let isDownloaded = FileManager.default.fileExists(atPath: destinationUrl.path)
        let symbolName = isDownloaded
            ? "checkmark.circle.fill"
            : "arrow.down.circle"
        let symbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: 22,
            weight: .semibold
        )

        let downloadImageView = UIImageView(
            image: UIImage(
                systemName: symbolName,
                withConfiguration: symbolConfiguration
            )
        )
        downloadImageView.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        downloadImageView.contentMode = .scaleAspectFit
        downloadImageView.isUserInteractionEnabled = false
        downloadImageView.accessibilityTraits = .image
        downloadImageView.tintColor = isDownloaded
            ? .systemGreen
            : GlobalConstants.kColor_DarkColor.withAlphaComponent(0.55)
        downloadImageView.accessibilityLabel = isDownloaded
            ? "Downloaded"
            : "Not downloaded"
        cell.accessoryView = downloadImageView
        
        return cell
    }
    
    
//   func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
//    
//    let row = indexPath.row
//    let section = indexPath.section
//    
//    let tempDict = seasonHymns![section].seasonSections
//    
//    for (_, v) in tempDict!{
//        //print ("k & V: \(k) -- > \(v) ")
//        //hymnDetailTemp = v
//        //print ("Number of hymns in section: \(v.count)")
//        print("+++++ hymn ID \(v[row].hymnID)")
//        print(v[row])
//        
//    }
//
//    
//    }
    
    
    
    // MARK: - Target/Action
    @IBAction func AddToPlayList(_ sender: Any) {
        performSegue(withIdentifier: "Add to Playlist", sender: self)
    }
    
    @IBAction func showHymn(_ sender: UITapGestureRecognizer)
    {
        performSegue(withIdentifier: "Show Hymn Detail", sender: sender.view)
        
    }
    
    // MARK: - Navigation
    
   override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let identifier = segue.identifier
        {
            switch identifier
            {
            case "Show Hymn Detail":
                guard let hymnDetailVC = segue.destination as? HymnDetailViewController else { return }

                let senderCell = sender as? UITableViewCell
                guard let indexPath = senderCell.flatMap({ tableView.indexPath(for: $0) })
                        ?? tableView.indexPathForSelectedRow,
                      let sections = seasonHymns,
                      sections.indices.contains(indexPath.section),
                      let hymns = sections[indexPath.section].seasonSections?.values.first,
                      hymns.indices.contains(indexPath.row) else { return }

                hymnDetailVC.hymnDetail = [hymns[indexPath.row]]
                
            case "Add to Playlist":
                print ("I'm going to add hymns to selected playlist")
                let playlistVC = segue.destination as! PlayListVC
                var hymnArrays: [PlayHymns]!
                
                
                for i in 0..<seasonHymns!.count{
                    
                    let tempDict = seasonHymns![i].seasonSections
                    for (_, v) in tempDict!{
                        print ("Number of hymns in section: \(v.count)")
                        for j in 0..<v.count{
                           // print(v[j].hymnName ?? <#default value#>)
                           let hymnArray = PlayHymns(HymnName: v[j].hymnName, HymnID: v[j].hymnID, HymnURL: v[j].hymnAudio)
                            //updateValue(v[j].hymnID, forKey: v[j].hymnName)
                            if hymnArrays == nil {
                                hymnArrays = [PlayHymns]()
                            }
                            hymnArrays.append(hymnArray)
                        }
                    }
                    
                playlistVC.plHymnsArray = hymnArrays
                playlistInstructions = true
                 //let newDict =
                    
                }
                print ("Going into playlist I have: \(hymnArrays.count)")
                
                                
            default:
                break
                
                
            }
        }
    }

    func unwindSegue(segue:UIStoryboardSegue) {
        if segue.identifier == "Show Hymn Detail" {
            
            self.tableView.reloadData()
        }
    }
}
