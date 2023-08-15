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

}



class SeasonViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {


    @IBOutlet var collectionView: UICollectionView!

    var seasonImages: [UIImage]!
    var seasonLabels: [UILabel]!
    var seasonsData: [SeasonData]!

    var iPath: IndexPath!

    var iSize: CGSize!
    var coverLayer: CALayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        // check version only if connected to Internet
        //if Reachability.isConnectedToNetwork(){
        //    update = CheckVersion()
        //}

        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "photo")!)

        coverLayer = CALayer()


        if (self.view.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.compact) {
            // Compact

            iSize = CGSize(width: collectionView.frame.width * 0.28, height: collectionView.frame.width * 0.28)


        } else {
            // Regular
            iSize = CGSize(width: collectionView.frame.width * 0.22, height: collectionView.frame.width * 0.22)

        }

        // MARK: Swipe controls
        let recognizer: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector (swipeLeft(recognizer:)))
        recognizer.direction = .left
        self.view .addGestureRecognizer(recognizer)


        updateUI()





    }

    override func viewDidAppear(_ animated: Bool) {
        // if DB updated
        if update{

            showUpdateAlertButton(in: self)
            update=false
        }
    }

    func updateUI()
    {
        seasonsData = DBManager.shared.loadSeasons()

    }

    // MARK: - Target/Action


    // MARK: - Collection View
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //print("@@@@@@@@@ GOING to have this many icons \(seasonsData.count)")

        return seasonsData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SeasonCollectionViewCell", for: indexPath as IndexPath) as! SeasonCollectionViewCell

        //print("!!!!!!!! \(seasonsData[indexPath.row])")

        cell.setSeasonItem(item: seasonsData[indexPath.row])
        return cell

    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
      //print("+++++++ User clicked on index \(indexPath.row)")
      //print("$$$ here is the season \(seasonsData[indexPath.row].seasonID)")
        performSegue(withIdentifier: "Show Season Detail", sender: [seasonsData[indexPath.row].seasonID as Any, seasonsData[indexPath.row].title as Any] as [Any] )

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

    @objc func swipeLeft(recognizer : UISwipeGestureRecognizer) {
        self.performSegue(withIdentifier: "Go To Playlist Segue", sender: self)
    }



}
