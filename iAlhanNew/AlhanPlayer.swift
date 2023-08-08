//
//  AlhanPlayer.swift
//  iAlhanNew
//
//  Created by Sidarous, Arsani on 10/21/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer


class AlhanPlayer {
    static let sharedInstance = AlhanPlayer()
    
    var player:AVPlayer = AVPlayer()
    var queuePlayer: AVQueuePlayer = AVQueuePlayer()
    var updater : CADisplayLink! = nil
    
    func play() {

      
        
        player.volume = 1.0
        //print("------ \(alhanPlayer.currentItem?.duration.seconds)")
        print("DESCRIPTION from inside the player \(String(describing: player.currentItem?.description))")
        print("Duration of the hymn from inside the player class \(String(describing: player.currentItem?.duration.seconds)) -- END")
        player.play()
        //player.allowsExternalPlayback = true

       
    }
    
    func playWithURL(playableURL : URL) {
        
       
        //let temp = "http://www.alhan.org/nativity/mp3/piouoiny2.mp3"
        let playerItem = AVPlayerItem(url: playableURL)
        player = AVPlayer(playerItem: playerItem)
        player.volume = 1.0
        //print("------ \(alhanPlayer.currentItem?.duration.seconds)")
        print("DESCRIPTION from inside the player \(String(describing: player.currentItem?.description))")
        print("Duration of the hymn from inside the player class \(String(describing: player.currentItem?.duration.seconds)) -- END")
        
        player.play()
        

    }
    
    func playQueue(playerURL: URL){
        let playerItem = AVPlayerItem(url: playerURL)
        queuePlayer.insert(playerItem, after: nil)
        //queuePlayer.play()
        //print("HYMN URL: \(playerURL)")

    }
    
    func getQueueCurrentItem() -> String{
       let temp = player.currentItem?.asset.description
//       let temp =  queuePlayer.currentItem?.asset
//        if (temp?.isKind(of: AVURLAsset.self))!{
//        
            print("TEMP: \(String(describing: temp))")
       // }
        return "\(String(describing: temp))"
    }
    
    func pauseQueue(){
        queuePlayer.pause()
    }
    
    func nextHymnInQueue(){
        if queuePlayer.rate == 1 {
            queuePlayer.advanceToNextItem()
        }        
    }
    
    func resetTimer(){
        AlhanPlayer.sharedInstance.player.currentItem?.seek(to: CMTimeMake(value: 0,timescale: 1))
        //ProgressBar.value = Float(0)
        
    }
    
    
  
    
           
}
