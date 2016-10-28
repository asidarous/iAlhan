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



class SeasonViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
//    // IBOutlet for images
//    @IBOutlet weak var seasonImage0: UIImageView!
//    @IBOutlet weak var seasonImage1: UIImageView!
//    @IBOutlet weak var seasonImage2: UIImageView!
//    @IBOutlet weak var seasonImage3: UIImageView!
//    @IBOutlet weak var seasonImage4: UIImageView!
//    @IBOutlet weak var seasonImage5: UIImageView!
//    @IBOutlet weak var seasonImage6: UIImageView!
//    @IBOutlet weak var seasonImage7: UIImageView!
//    @IBOutlet weak var seasonImage8: UIImageView!
//    @IBOutlet weak var seasonImage9: UIImageView!
//    @IBOutlet weak var seasonImage10: UIImageView!
//    @IBOutlet weak var seasonImage11: UIImageView!
//    
//    // IBOutlet for labels
//    @IBOutlet weak var SeasonLabel_0: UILabel!
//    @IBOutlet weak var SeasonLabel_1: UILabel!
//    @IBOutlet weak var SeasonLabel_2: UILabel!
//    @IBOutlet weak var SeasonLabel_3: UILabel!
//    @IBOutlet weak var SeasonLabel_4: UILabel!
//    @IBOutlet weak var SeasonLabel_5: UILabel!
//    @IBOutlet weak var SeasonLabel_6: UILabel!
//    @IBOutlet weak var SeasonLabel_7: UILabel!
//    @IBOutlet weak var SeasonLabel_8: UILabel!
//    @IBOutlet weak var SeasonLabel_9: UILabel!
//    @IBOutlet weak var SeasonLabel_10: UILabel!
//    @IBOutlet weak var SeasonLabel_11: UILabel!
    
    @IBOutlet var collectionView: UICollectionView!
    
    var seasonImages: [UIImage]!
    var seasonLabels: [UILabel]!
    var seasonsData: [SeasonData]!
    
    var iPath: IndexPath!
    
    var iSize: CGSize!
    var coverLayer: CALayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "crossbck_sml")!)
        coverLayer = CALayer()
        
//        // append all seasonImages to the array
//        seasonImages = [seasonImage0, seasonImage1, seasonImage2, seasonImage3, seasonImage4, seasonImage5, seasonImage6, seasonImage7, seasonImage8, seasonImage9, seasonImage10, seasonImage11]
       
        
//        
//        // append all seasonLabels to the array
//        seasonLabels = [SeasonLabel_0, SeasonLabel_1, SeasonLabel_2, SeasonLabel_3, SeasonLabel_4, SeasonLabel_5, SeasonLabel_6, SeasonLabel_7, SeasonLabel_8, SeasonLabel_9, SeasonLabel_10, SeasonLabel_11]
//        
        // method to set the images of the IBOutlets
        
        if (self.view.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.compact) {
            // Compact
            
            iSize = CGSize(width: collectionView.frame.width * 0.28, height: collectionView.frame.width * 0.28)

            
        } else {
            // Regular
            iSize = CGSize(width: collectionView.frame.width * 0.22, height: collectionView.frame.width * 0.22)
            
        }
        
        
        updateUI()
        
        
        
    }

    func updateUI()
    {
        seasonsData = DBManager.shared.loadSeasons()
        
//        for i in 0..<seasonsData.count-1 {
//            print ("!!!! \(i)")
//            seasonImages.append(UIImage (named: seasonsData[i].seasonImage)!)
//        }
//        for i in 0..<seasonImages.count-1{
//            let seasonImage = seasonImages[i]
//            
//            let album = seasonsData[i]
//            //print (album.seasonImage!)
//            seasonImage.image = UIImage(named: album.seasonImage!)
//            seasonLabels[i].text = album.title
//         }
    }
    
    // MARK: - Target/Action
    
//    @IBAction func showSeason(_ sender: UITapGestureRecognizer)
//    {
//        let point: CGPoint = sender.location(in: collectionView)
//        
//        iPath = collectionView.indexPathForItem(at: point)!
//        
//        performSegue(withIdentifier: "Show Season Detail", sender: sender.view)
//        
//    }
    
    // MARK: - Collection View
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("@@@@@@@@@ GOING to have this many icons \(seasonsData.count)")
        
        return seasonsData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SeasonCollectionViewCell", for: indexPath as IndexPath) as! SeasonCollectionViewCell
        
        print("!!!!!!!! \(seasonsData[indexPath.row])")
            
        cell.setSeasonItem(item: seasonsData[indexPath.row])
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
      print("+++++++ User clicked on index \(indexPath.row)")
      print("$$$ here is the season \(seasonsData[indexPath.row].seasonID)")
      performSegue(withIdentifier: "Show Season Detail", sender: [seasonsData[indexPath.row].seasonID, seasonsData[indexPath.row].title] )
    
    }
    

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        

        var vSize: CGSize
        
        
        if (self.view.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.compact) {
            // Compact
            
            vSize = CGSize(width: collectionView.frame.width * 0.28, height: (collectionView.frame.width * 0.28)+25)
            
        } else {
            // Regular

            vSize = CGSize(width: collectionView.frame.width * 0.22, height: (collectionView.frame.width * 0.22)+35)
        }
        
        
        return vSize
    }
    
    // MARK:- UICollectionViewDelegate Methods

    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        //cell?.addSubview(tempView)
        
        coverLayer.frame = CGRect(origin: collectionView.frame.origin, size: iSize)
        coverLayer.backgroundColor = UIColor.black.cgColor
        coverLayer.opacity = 0.1
        cell?.layer.addSublayer(coverLayer)
        
            
            //.backgroundColor = UIColor.red
    }
    
    // change background color back when user releases touch
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor.clear
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
                    //var point:CGPoint = sender. .locationInView(collectionView)
                    //print("#### \(self.collectionView.indexPathForItem(at: point))")

                    let data = sender as! NSArray
                    //print (detailImageView)da
                    //if let index = seasonImages.index(of: detailImageView)
                    //{
                    
                        let seasonID = data[0]
                        let hymnArray = DBManager.shared.loadSeasonHymns(WithID: seasonID as! Int)
                        
                        //print ("Print from within SeasonVC \(hymnArray)")
                        seasonDetailVC.labelText = data[1] as? String
                        seasonDetailVC.seasonHymns = hymnArray
                
                    //}
               
            
                
                default:
                    break
            
            
            }
        }
    }
    
    
    
    
}
