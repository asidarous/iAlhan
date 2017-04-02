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

class PlayListVC: UITableViewController {
    @IBOutlet var PlayListItemsTable: UITableView!
    
    var plArray: [String]!

    var plHymnsArray: [PlayHymns] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        NotificationCenter.default.addObserver(self, selector: #selector (loadList(notification:)),name:NSNotification.Name(rawValue: "load"), object: nil)
        
        plArray = PL_DBManager.shared.getPL()
        
        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = true

        
        if playlistInstructions == true {
            let alert = UIAlertController(title: "Add to playlist", message: "Please select an exiting playlist, or click + to create a new playlist.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            playlistInstructions = false
        }
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func loadList(notification: NSNotification){
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
            cell.textLabel?.text = plArray?[row].description
        }
        
        
        
        return cell
    }
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        if plHymnsArray.isEmpty {
        performSegue(withIdentifier: "Show Playlist Detail", sender: plArray[indexPath.row])
        }
        else
        {
           // get playlist ID
            let playlistID = PL_DBManager.shared.getPLID(playlist: plArray[indexPath.row])
            
            print("Here is the playlist ID \(playlistID)")
            
            // insert hymns into playlist DB (listdetails)
            PL_DBManager.shared.addHymnsToPL(playlist: playlistID, hymnLists: plHymnsArray)
            performSegue(withIdentifier: "Show Playlist Detail", sender: plArray[indexPath.row])
            print (plHymnsArray)
            plHymnsArray.removeAll()
        }
    }
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        let row = indexPath.row
        let cell = self.tableView.cellForRow(at: indexPath)
        
        if editingStyle == .delete {
            // Delete the row from the data source
            
            PL_DBManager.shared.deletePL(playlist: (cell?.textLabel?.text)!)
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
