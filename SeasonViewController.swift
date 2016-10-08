//
//  SeasonViewController.swift
//  iAlhanNew
//
//  Created by Sidarous, Arsani on 10/7/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import UIKit

class SeasonViewController: UIViewController {

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

    
    var seasonImages: [UIImageView]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "photo.jpg")!);
        
        // append all seasonImages to the array
        seasonImages = [seasonImage0, seasonImage1, seasonImage2, seasonImage3, seasonImage4, seasonImage5, seasonImage6, seasonImage7, seasonImage8, seasonImage9, seasonImage10, seasonImage11]
        
        // method to set the images of the IBOutlets
       updateUI()
        
    }

    func updateUI()
    {
        for i in 0..<seasonImages.count{
            let seasonImage = seasonImages[i]
            
            let album = Season(index: i)
            //if (album.seasonImage != nil)
            //{
                seasonImage.image = UIImage(named: album.seasonImage!)
            //}
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
                        //print ("Index: ")
                        //print (index)
                        let album = Season.init(index: index)
                        seasonDetailVC.album = album
                        
                    }
            
                
                default:
                    break
            
            
            }
        }
    }
    
    
    
    
}
