//
//  PlaylistDetailVC.swift
//  iAlhan
//
//  Created by ARSANI SIDAROUS on 10/30/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import UIKit

struct PlaylistHymns{
    
    var HymnName: String!
    var HymnID: Int!
}

class PlaylistDetailVC:  UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var plDetail: UITableView!
    
    var playlistHymns:[PlaylistHymns]?
    
    override func viewDidLoad() {
        super.viewDidLoad()


        
    playlistHymns = PL_DBManager.shared.getPLHymns(playlist: self.title!)
        print("\(playlistHymns?.count)")
        // Do any additional setup after loading the view.
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return (playlistHymns?.count)!
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell  {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "hymnCell", for: indexPath)
        
        let row = indexPath.row
        
        print("just outside")
        if ((playlistHymns?.count)! > 0)
        {
            print("Got in")
            cell.textLabel?.text = playlistHymns?[row].HymnName
        }
        
        
        
        return cell
    }
    

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
