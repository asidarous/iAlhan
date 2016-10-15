//
//  SeasonViewController.swift
//  iAlhanNew
//
//  Created by Sidarous, Arsani on 10/7/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import UIKit

struct SeasonData {
    var title: String!
    var seasonImage: String!
    var seasonID: Int!
    //var seasonSections: [String : [String]]!
}



class SeasonViewController: UIViewController {
    
    // IBOutlet for images
    @IBOutlet weak var seasonImage0: UIImageView!
    @IBOutlet weak var seasonImage1: UIImageView!
    @IBOutlet weak var seasonImage2: UIImageView!
    @IBOutlet weak var seasonImage3: UIImageView!
    @IBOutlet weak var seasonImage4: UIImageView!
    @IBOutlet weak var seasonImage5: UIImageView!
    @IBOutlet weak var seasonImage6: UIImageView!
    @IBOutlet weak var seasonImage7: UIImageView!
    @IBOutlet weak var seasonImage8: UIImageView!
    @IBOutlet weak var seasonImage9: UIImageView!
    @IBOutlet weak var seasonImage10: UIImageView!
    @IBOutlet weak var seasonImage11: UIImageView!
    
    // IBOutlet for labels
    @IBOutlet var seasonLabel0: UITextField!
    @IBOutlet var seasonLabel1: UITextField!
    @IBOutlet var seasonLabel2: UITextField!
    @IBOutlet var seasonLabel3: UITextField!
    @IBOutlet var seasonLabel4: UITextField!
    @IBOutlet var seasonLabel5: UITextField!
    @IBOutlet var seasonLabel6: UITextField!
    @IBOutlet var seasonLabel7: UITextField!
    @IBOutlet var seasonLabel8: UITextField!
    @IBOutlet var seasonLabel9: UITextField!
    @IBOutlet var seasonLabel10: UITextField!
    @IBOutlet var seasonLabel11: UITextField!

    
    var seasonImages: [UIImageView]!
    var seasonLabels: [UITextField]!
    var seasonsData: [SeasonData]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "photo.jpg")!);
        
        // append all seasonImages to the array
        seasonImages = [seasonImage0, seasonImage1, seasonImage2, seasonImage3, seasonImage4, seasonImage5, seasonImage6, seasonImage7, seasonImage8, seasonImage9, seasonImage10, seasonImage11]
        
        // append all seasonLabels to the array
        seasonLabels = [seasonLabel0, seasonLabel1, seasonLabel2, seasonLabel3, seasonLabel4, seasonLabel5, seasonLabel6, seasonLabel7, seasonLabel8, seasonLabel9, seasonLabel10, seasonLabel11]
        
        // method to set the images of the IBOutlets
        updateUI()
        
        
        
    }

    func updateUI()
    {
        seasonsData = DBManager.shared.loadSeasons()
        
        for i in 0..<seasonImages.count-1{
            let seasonImage = seasonImages[i]
            
            let album = seasonsData[i]
            //print (album.seasonImage!)
            seasonImage.image = UIImage(named: album.seasonImage!)
            seasonLabels[i].text = album.title
         }
    }
    
    // MARK: - Target/Action
    
    @IBAction func showSeason(_ sender: UITapGestureRecognizer)
    {
        performSegue(withIdentifier: "Show Season Detail", sender: sender.view)
        
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let identifier = segue.identifier
        {
            switch identifier
            {
                case "Show Season Detail":
                    //print ("I'm here")
                    let seasonDetailVC = segue.destination as! SeasonDetailViewController
                    //print (seasonDetailVC.detailTextView)
                    let detailImageView = sender as! UIImageView
                    //print (detailImageView)
                    if let index = seasonImages.index(of: detailImageView)
                    {

                        let seasonID = seasonsData[index].seasonID
                        let hymnArray = DBManager.shared.loadSeasonHymns(WithID: seasonID!)
                        
                        print ("Print from within SeasonVC \(hymnArray)")
                        seasonDetailVC.labelText = seasonsData[index].title
                        seasonDetailVC.seasonHymns = hymnArray
                        
                    }
            
                
                default:
                    break
            
            
            }
        }
    }
    
    
    
    
}
