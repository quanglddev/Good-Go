//
//  LyricsVC.swift
//  Music ++
//
//  Created by QUANG on 1/21/17.
//  Copyright © 2017 Q.U.A.N.G. All rights reserved.
//

import UIKit
import MediaPlayer
import MarqueeLabel

class LyricsVC: UIViewController {

    //MARK: Properties
    let defaults = UserDefaults.standard
    
    let player = MPMusicPlayerController.systemMusicPlayer()
    
    var nowPlayingItemDidChangeObserver: AnyObject?
    
    var songs: [MPMediaItem] = []
    var titles: [String] = []
    var lyrics: [String] = []
    
    struct defaultsKeys {
        static let lyricForIndex = "lyricForIndex"
        static let shouldOpenLyricNotNowPlaying = "shouldOpenLyricNotNowPlaying"
    }
    
    //MARK: Outlets
    @IBOutlet var audioPlaybackSlider: UISlider?
    
    @IBOutlet var lblPlaybackCurrent: UILabel?
    @IBOutlet var lblPlaybackETA: UILabel?
    
    @IBOutlet var lyricsTextView: UITextView?
    
    @IBOutlet var lblName: MarqueeLabel!
    
    
    //MARK: Actions
    @IBAction func audioPlaybackTouched(_ sender: UISlider) {
        isAutoUpdatingPlayback = false
    }
    
    
    @IBAction func aa(_ sender: UISlider) {
        if player.playbackState == .playing {
            player.pause()
            isPlaying = true
            currentDurationOnPause = TimeInterval(audioPlaybackSlider!.value)
        }
        else {
            isPlaying = false
        }
        player.currentPlaybackTime = TimeInterval((audioPlaybackSlider?.value)!)
        
        if isPlaying {
            player.play()
        }
        
        isAutoUpdatingPlayback = true
        print("end2")    }

    
    var isPlaying = true
    var currentDurationOnPause: TimeInterval = 0

    
    //MARK: Defaults
    deinit {
        NotificationCenter.default.removeObserver(self.nowPlayingItemDidChangeObserver!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let mediaItems = MPMediaQuery.songs().items {
            for mediaItem in mediaItems {
                self.songs.append(mediaItem)
                self.lyrics.append(mediaItem.lyrics ?? "No Lyrics")
                self.titles.append(mediaItem.title ?? "No Name")
            }
        }

        self.player.beginGeneratingPlaybackNotifications()
        
        self.nowPlayingItemDidChangeObserver =  NotificationCenter.default.addObserver(forName: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: nil, queue: OperationQueue.main, using: { (notification) -> Void in
            
            self.update()
        })
        
        let _ = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.updateAudioPlaybackSlider), userInfo: nil, repeats: true)
        let _ = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
        
        let thumbImage: UIImage = #imageLiteral(resourceName: "ironman-cm11-theme-icon")
        let size = CGSize(width: 20, height: 20)
        audioPlaybackSlider?.setThumbImage(thumbImage.imageWithImage(image: thumbImage, scaledToSize: size), for: .normal)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(returnBackHome))
        lyricsTextView?.addGestureRecognizer(longPress)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(pausePlayWhatever))
        lblName.addGestureRecognizer(tap)
        lblName.isUserInteractionEnabled = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    //MARK: Private Methods
    func returnBackHome() {
        dismiss(animated: true, completion: nil)
    }
    
    func pausePlayWhatever() {
        if player.playbackState == .playing {
            if let nowPlayingItem = self.player.nowPlayingItem {
                if let index = songs.index(of: nowPlayingItem) {
                    if lyrics[index] == lyricsTextView?.text {
                        player.pause()
                    }
                    else { //Play another song (song index is saved in lyricForIndex
                        let index = defaults.integer(forKey: defaultsKeys.lyricForIndex)
                        
                        if let song = songs[safe: index] {
                            let media = MPMediaItemCollection(items: [song])
                            
                            self.player.setQueue(with: media)
                            player.play()
                        }
                    }
                }
            }
        }
        else {
            if let nowPlayingItem = self.player.nowPlayingItem {
                if let index = songs.index(of: nowPlayingItem) {
                    if lyrics[index] == lyricsTextView?.text {
                        player.play()
                    }
                    else { //Play another song (song index is saved in lyricForIndex
                        let index = defaults.integer(forKey: defaultsKeys.lyricForIndex)
                        
                        if let song = songs[safe: index] {
                            let media = MPMediaItemCollection(items: [song])
                            
                            self.player.setQueue(with: media)
                            player.play()
                        }
                    }
                }
            }
        }
    }
    
    var isAutoUpdatingPlayback = true
    func updateAudioPlaybackSlider() {
        if isAutoUpdatingPlayback {
            if player.playbackState == .playing {
                //Update audio slider value
                audioPlaybackSlider?.value = Float(player.currentPlaybackTime)
                
                let formatter = DateComponentsFormatter()
                formatter.unitsStyle = .positional
                formatter.allowedUnits = [.minute, .second ]
                formatter.zeroFormattingBehavior = [ .pad ]
                
                //Update playing time label
                let curDur: TimeInterval = player.currentPlaybackTime // Song's current time
                lblPlaybackCurrent?.text = formatter.string(from: curDur)
                
                let remDur: TimeInterval = TimeInterval(Int(audioPlaybackSlider!.maximumValue) - Int(player.currentPlaybackTime))
                lblPlaybackETA?.text = "-\(formatter.string(from: remDur)!)"
            }
            
            /*
            if player.playbackState == .playing {
                var min = String(Int(player.currentPlaybackTime) / 60)
                if min.characters.count == 1 {
                    min = "0\(String(min)!)"
                }
                var sec = String(Int(player.currentPlaybackTime) % 60)
                if sec.characters.count == 1 {
                    sec = "0\(String(sec)!)"
                }
                lblPlaybackCurrent?.text = "\(min):\(sec)"
                
                var remainMin = String(Int((Int((audioPlaybackSlider?.maximumValue)!) - Int(player.currentPlaybackTime)) / 60))
                if remainMin.characters.count == 1 {
                    remainMin = "0\(String(remainMin)!)"
                }
                var remainSec = String(Int((Int((audioPlaybackSlider?.maximumValue)!) - Int(player.currentPlaybackTime)) % 60))
                if remainSec.characters.count == 1 {
                    remainSec = "0\(String(remainSec)!)"
                }
                lblPlaybackETA?.text = "-\(remainMin):\(remainSec)"
            }*/
        }
    }
    
    func update() {
        let shouldOpenLyricNotNowPlaying = defaults.bool(forKey: defaultsKeys.shouldOpenLyricNotNowPlaying)
        
        if !shouldOpenLyricNotNowPlaying {
            if let nowPlayingItem = self.player.nowPlayingItem {
                if let index = songs.index(of: nowPlayingItem) {
                    lyricsTextView?.text = lyrics[index]
                    
                    audioPlaybackSlider?.maximumValue = Float(songs[index].playbackDuration)
                    
                    lblName.text = titles[index]
                }
                else { //Show lyric for song that is not playing saved in lyricForIndex default
                    print("error baby")
                }
            }
        }
        else {
            let index = defaults.integer(forKey: defaultsKeys.lyricForIndex)
            lyricsTextView?.text = lyrics[index]
            
            audioPlaybackSlider?.maximumValue = Float(songs[index].playbackDuration)
            
            lblName.text = titles[index]
        }
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
