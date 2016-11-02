//
//  AlhanPlayer.swift
//  iAlhanNew
//
//  Created by Sidarous, Arsani on 10/21/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import Foundation
import AVFoundation

class AlhanPlayer {
    static let sharedInstance = AlhanPlayer()
    
    var player:AVPlayer = AVPlayer()
    var queuePlayer: AVQueuePlayer = AVQueuePlayer()
    var updater : CADisplayLink! = nil
    
    func play() {

       
        
        player.volume = 1.0
        //print("------ \(alhanPlayer.currentItem?.duration.seconds)")
        print("DESCRIPTION from inside the player \(player.currentItem?.description)")
        print("Duration of the hymn from inside the player class \(player.currentItem?.duration.seconds) -- END")
        player.play()
        
    }
    
    func playWithURL(playableURL : URL) {

        //let temp = "http://www.alhan.org/nativity/mp3/piouoiny2.mp3"
        let playerItem = AVPlayerItem(url: playableURL)
        player = AVPlayer(playerItem: playerItem)
        player.volume = 1.0
        //print("------ \(alhanPlayer.currentItem?.duration.seconds)")
        print("DESCRIPTION from inside the player \(player.currentItem?.description)")
        print("Duration of the hymn from inside the player class \(player.currentItem?.duration.seconds) -- END")
        
        player.play()
        

    }
    
    func playQueue(playerURL: URL){
        let playerItem = AVPlayerItem(url: playerURL)
        queuePlayer.insert(playerItem, after: nil)
        queuePlayer.play()
    }
    
    func resetTimer(){
        AlhanPlayer.sharedInstance.player.currentItem?.seek(to: CMTimeMake(0,1))
        //ProgressBar.value = Float(0)
        
    }
    
    
  
    
           
}
