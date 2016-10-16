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
    @IBOutlet weak var SeasonLabel_0: UILabel!
    @IBOutlet weak var SeasonLabel_1: UILabel!
    @IBOutlet weak var SeasonLabel_2: UILabel!
    @IBOutlet weak var SeasonLabel_3: UILabel!
    @IBOutlet weak var SeasonLabel_4: UILabel!
    @IBOutlet weak var SeasonLabel_5: UILabel!
    @IBOutlet weak var SeasonLabel_6: UILabel!
    @IBOutlet weak var SeasonLabel_7: UILabel!
    @IBOutlet weak var SeasonLabel_8: UILabel!
    @IBOutlet weak var SeasonLabel_9: UILabel!
    @IBOutlet weak var SeasonLabel_10: UILabel!
    @IBOutlet weak var SeasonLabel_11: UILabel!
    
    var seasonImages: [UIImageView]!
    var seasonLabels: [UILabel]!
    var seasonsData: [SeasonData]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "photo.jpg")!);
        
        // append all seasonImages to the array
        seasonImages = [seasonImage0, seasonImage1, seasonImage2, seasonImage3, seasonImage4, seasonImage5, seasonImage6, seasonImage7, seasonImage8, seasonImage9, seasonImage10, seasonImage11]
        
        // append all seasonLabels to the array
        seasonLabels = [SeasonLabel_0, SeasonLabel_1, SeasonLabel_2, SeasonLabel_3, SeasonLabel_4, SeasonLabel_5, SeasonLabel_6, SeasonLabel_7, SeasonLabel_8, SeasonLabel_9, SeasonLabel_10, SeasonLabel_11]
        
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
                        
                        //print ("Print from within SeasonVC \(hymnArray)")
                        seasonDetailVC.labelText = seasonsData[index].title
                        seasonDetailVC.seasonHymns = hymnArray
                        
                    }
            
                
                default:
                    break
            
            
            }
        }
    }
    
    
    
    
}
