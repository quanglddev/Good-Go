//
//  ViewController.swift
//  Music ++
//
//  Created by QUANG on 1/16/17.
//  Copyright © 2017 Q.U.A.N.G. All rights reserved.
//

import UIKit
import CircularSlider
import MediaPlayer
import SCLAlertView
import MarqueeLabel
import os.log

class ViewController: UIViewController, iCarouselDataSource, iCarouselDelegate {
    
    //MARK: Properties
    var artworks: [UIImage] = []
    var songs: [MPMediaItem] = []
    var songTitles: [String] = []
    var songArtists: [String] = []
    var songLengths: [Double] = []
    var lyrics: [String] = []
    
    var likes: [Bool] = []
    var userSongIDs: [MPMediaEntityPersistentID] = []
    var savedSongIDs: [LikesArray] = []
    
    var playlists: [MPMediaItemCollection] = []
    var playlistsRepresentativeImages: [UIImage] = []
    var playlistTitles: [String] = []
    
    var albums: [MPMediaItemCollection] = []
    var albumTitles: [String] = []
    var albumRepresentativeImages: [UIImage] = []
    
    var shuffledMedium: [MPMediaItem] = []
    
    var allSongsWithCustomStart: [MPMediaItem] = []
    
    var lastSongSliderValueForSongs = 0  //Because slider return unnecessary value: 0.45 when we just need simple value like 1
    var lastSongSliderValueForPlaylists = 0 //Same above
    var lastSongSliderValueForAlbums = 0 //Same above
    
    var curPlayingSong = 0 //Index
    //var currentSelection2 = 0
    //var currentSelection3 = 0
    
    //var playingIndex = 0
    var curPlayingPlaylist = 0
    var curPlayingAlbum = 0
    
    var lastCarouselValueForSongs = 0 //Because slider return unnecessary value: 0.45 when we just need simple value like 1
    var lastCarouselValueForPlaylists = 0
    var lastCarouselValueForAlbums = 0
    
    //var currentShuffledIndex = 0
    var lastSelectedSongIndex = 0 //For moving among sources
    
    //var isPlaying = true
    var isShuffling = false
    var isAutoUpdatingPlayback = true
    
    let player = MPMusicPlayerController.systemMusicPlayer()
    var nowPlayingItemDidChangeObserver: AnyObject?
    
    struct defaultsKeys {
        static let repeatSegment = "repeatSegment"
        static let sourceSegment = "sourceSegment"
        static let isFirstLaunch = "firstTimeRunApp"
        static let isReflectionOn = "isReflectionOn"
        static let isAutoStopOn = "isAutoStopOn"
        static let timeBeforeStop = "timeBeforeStop"
        static let lyricForIndex = "lyricForIndex"
        static let shouldOpenLyricNotNowPlaying = "shouldOpenLyricNotNowPlaying"
    }
    
    let defaults = UserDefaults.standard
    
    //MARK: Outlets
    @IBOutlet var assistantImageView: UIImageView!
    @IBOutlet var lblPlaybackCurrent: UILabel!
    @IBOutlet var lblPlaybackETA: UILabel!
    @IBOutlet var shortcutView: UIView!
    @IBOutlet var songSlider: CircularSlider!
    @IBOutlet var carouselView: iCarousel!
    @IBOutlet weak var lblTitleSong: UILabel!
    @IBOutlet weak var audioPlaybackSlider: UISlider!
    @IBOutlet weak var gestureHandlerView: UIView!
    @IBOutlet var sourceSegment: UISegmentedControl?
    @IBOutlet var repeatSegment: UISegmentedControl!
    @IBOutlet var likedView: UIView!
    @IBOutlet var lblCurrentlyPlaying: MarqueeLabel!
    
    @IBOutlet var settingsImageView: UIImageView!
    //MARK: Default
    deinit {
        carouselView.delegate = nil;
        carouselView.dataSource = nil;
        NotificationCenter.default.removeObserver(self.nowPlayingItemDidChangeObserver!)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let isFirstLaunch = !self.defaults.bool(forKey: defaultsKeys.isFirstLaunch)
        if isFirstLaunch { //Set default value
            defaults.set(false, forKey: defaultsKeys.isReflectionOn)
            defaults.set(true, forKey: defaultsKeys.isAutoStopOn)
            defaults.set(3600.00000, forKey: defaultsKeys.timeBeforeStop)
            
            defaults.set(true, forKey: defaultsKeys.isFirstLaunch)
            print("isFirstLaunch")
        }
        
        //UIApplication.shared.isIdleTimerDisabled = true
        
        DispatchQueue.main.async {
            self.assistantImageView.layer.borderWidth = 1
            self.assistantImageView.layer.masksToBounds = false
            self.assistantImageView.layer.borderColor = UIColor.yellow.cgColor
            self.assistantImageView.layer.cornerRadius = self.assistantImageView.frame.height / 2
            self.assistantImageView.clipsToBounds = true
            self.assistantImageView.isUserInteractionEnabled = true
            
            self.settingsImageView.layer.borderWidth = 1
            self.settingsImageView.layer.masksToBounds = false
            self.settingsImageView.layer.borderColor = UIColor.lightGray.cgColor
            self.settingsImageView.layer.cornerRadius = self.settingsImageView.frame.height / 2
            self.settingsImageView.clipsToBounds = true
            self.settingsImageView.isUserInteractionEnabled = true
            
            
            let tapSettings = UITapGestureRecognizer(target: self, action: #selector(self.toSettingsVC))
            self.settingsImageView.addGestureRecognizer(tapSettings)
            
            let thumbImage: UIImage = #imageLiteral(resourceName: "ironman-cm11-theme-icon")
            let size = CGSize(width: 20, height: 20)
            self.audioPlaybackSlider.setThumbImage(thumbImage.imageWithImage(image: thumbImage, scaledToSize: size), for: .normal)
            
            self.sourceSegment?.selectedSegmentIndex = 0
            
            let repeatValue = self.defaults.integer(forKey: defaultsKeys.repeatSegment)
            self.repeatSegment?.selectedSegmentIndex = repeatValue
            
            if repeatValue == 0 {
                self.player.repeatMode = .all
            }
            else if repeatValue == 1 {
                self.player.repeatMode = .one
            }
            else if repeatValue == 2 {
                self.player.repeatMode = .none
            }
            
            self.setupCircularSlider()
            //self.setupTapGesture()
            
            MPMediaLibrary.requestAuthorization { (status) in
                if status == .authorized {
                    print("Authorized")
                    if let mediaItems = MPMediaQuery.songs().items {
                        for mediaItem in mediaItems {
                            self.artworks.append(((mediaItem.artwork?.image(at: CGSize(width: self.carouselView.frame.width / 3 * 2, height: self.carouselView.frame.width / 3 * 2))) ?? self.buildCustomAlbumArt(song: mediaItem)))
                            //print("check100")
                            self.songs.append(mediaItem)
                            self.songTitles.append(mediaItem.title ?? "No Name")
                            self.songArtists.append(mediaItem.artist ?? "Various Artists")
                            self.songLengths.append(mediaItem.playbackDuration)
                            self.lyrics.append(mediaItem.lyrics ?? "No lyrics")
                            self.userSongIDs.append(mediaItem.persistentID)
                            
                            //self.likeIts.append(LikeIt(ID: mediaItem.persistentID, liked: true)!)
                        }
                        
                        self.carouselView.type = .cylinder
                        self.carouselView.reloadData()
                        self.carouselView.scrollToItemBoundary = true
                        
                        //Create gesture
                        let upSwipe = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipes))
                        let downSwipe = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipes))
                        
                        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(self.songSwipe))
                        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(self.songSwipe))
                        
                        rightSwipe.direction = .right
                        leftSwipe.direction = .left
                        
                        self.shortcutView.addGestureRecognizer(rightSwipe)
                        self.shortcutView.addGestureRecognizer(leftSwipe)
                        
                        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.carousel(_:didSelectItemAt:)))
                        
                        upSwipe.direction = .up
                        downSwipe.direction = .down
                        
                        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.toPlayingSong))
                        
                        self.shortcutView.addGestureRecognizer(longPress)
                        
                        self.gestureHandlerView.addGestureRecognizer(upSwipe)
                        self.gestureHandlerView.addGestureRecognizer(downSwipe)
                        
                        self.shortcutView.addGestureRecognizer(tapGesture)
                        
                        //print("pass1")
                        
                        if self.player.repeatMode == .all {
                            self.repeatSegment.selectedSegmentIndex = 0
                        }
                        else if self.player.repeatMode == .one {
                            self.repeatSegment.selectedSegmentIndex = 1
                        }
                        else if self.player.repeatMode == .none {
                            self.repeatSegment.selectedSegmentIndex = 2
                        }
                    }
                    
                    if let mediaItems = MPMediaQuery.songs().items {
                        /*
                         let isFirstLaunch = self.defaults.bool(forKey: defaultsKeys.isFirstLaunch)
                         if !isFirstLaunch {
                         for mediaItem in mediaItems {
                         self.savedSongIDs.append(LikesArray(ID: mediaItem.persistentID, isLiked: true)!)
                         }
                         }
                         else {
                         self.loadSavedLikesArray()
                         }*/
                        
                        if let savedLikesArray = self.loadSavedLikesArray() {
                            self.savedSongIDs += savedLikesArray
                            //print("\(savedSongIDs.count) \()")
                            if self.savedSongIDs.count != self.songs.count {
                                // Reset.
                                self.savedSongIDs.removeAll()
                                for mediaItem in mediaItems {
                                    self.savedSongIDs.append(LikesArray(ID: mediaItem.persistentID, isLiked: true)!)
                                }
                            }
                        }
                        else{
                            // Load the sample data.
                            for mediaItem in mediaItems {
                                self.savedSongIDs.removeAll()
                                self.savedSongIDs.append(LikesArray(ID: mediaItem.persistentID, isLiked: true)!)
                            }
                        }
                    }
                    
                    self.setupLikes()
                    
                    if let playlistItems = MPMediaQuery.playlists().collections {
                        for playlist in playlistItems {
                            self.playlists.append(playlist)
                            self.playlistsRepresentativeImages.append((playlist.representativeItem?.artwork?.image(at: CGSize(width: self.carouselView.frame.width / 3 * 2, height: self.carouselView.frame.width / 3 * 2))) ?? #imageLiteral(resourceName: "defaultPhoto"))
                            self.playlistTitles.append(playlist.value(forProperty: MPMediaPlaylistPropertyName) as! String? ?? "No name")
                            //print("check100")
                            //print(playlist.value(forProperty: MPMediaPlaylistPropertyName) ?? "No name")
                        }
                    }
                    
                    if let albumItems = MPMediaQuery.albums().collections {
                        for album in albumItems {
                            self.albums.append(album)
                            self.albumRepresentativeImages.append((album.representativeItem?.artwork?.image(at: CGSize(width: self.carouselView.frame.width / 3 * 2, height: self.carouselView.frame.width / 3 * 2))) ?? #imageLiteral(resourceName: "defaultPhoto"))
                            self.albumTitles.append("\(album.items[0].albumTitle ?? "No name")")
                            //print(album.value(forProperty: ) ?? "No name")
                        }
                    }
                    
                    self.songSlider.maximumValue = Float(self.songs.count)
                    //print(self.songCount)
                    //print(self.songSlider.maximumValue)
                    
                    self.player.beginGeneratingPlaybackNotifications()
                    
                    self.nowPlayingItemDidChangeObserver =  NotificationCenter.default.addObserver(forName: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: nil, queue: OperationQueue.main, using: { (notification) -> Void in
                        
                        print("YOLO YOLO")
                        self.updateNowPlayingItem()
                    })
                    /*
                     let delay = 10
                     
                     DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delay), execute: {
                     //Scroll to current playing song
                     self.updateNowPlayingItem()
                     })*/
                    
                    //Scroll to current playing song
                    self.updateNowPlayingItem()
                    
                    let tapLikeBtn = UITapGestureRecognizer(target: self, action: #selector(self.likeIt))
                    self.likedView.addGestureRecognizer(tapLikeBtn)
                }
                else {
                    //print("Access denied!")
                    self.displayMediaLibraryError()
                }
            }
        }
        //print("pass1")
        let _ = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateAudioPlaybackSlider), userInfo: nil, repeats: true)
        
    }
    
    fileprivate func setupCircularSlider() {
        songSlider.delegate = self
    }
    
    /*
     fileprivate func setupTapGesture() {
     let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
     view.addGestureRecognizer(tapGesture)
     }*/
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        //free up memory by releasing subviews
        self.carouselView = nil;
    }
    
    /*
     @objc fileprivate func hideKeyboard() {
     view.endEditing(true)
     }*/
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateStartup()
    }
    
    //MARK: Actions
    @IBAction func audioPlayerTouched(_ sender: UISlider) {
        isAutoUpdatingPlayback = false
    }
    
    @IBAction func repeatSegmentChanged(_ sender: UISegmentedControl) {
        if repeatSegment.selectedSegmentIndex == 0 {
            self.player.repeatMode = MPMusicRepeatMode.all
            defaults.setValue(0, forKey: defaultsKeys.repeatSegment)
        }
        else if repeatSegment.selectedSegmentIndex == 1 {
            self.player.repeatMode = MPMusicRepeatMode.one
            defaults.setValue(1, forKey: defaultsKeys.repeatSegment)
        }
        else if repeatSegment.selectedSegmentIndex == 2 {
            self.player.repeatMode = MPMusicRepeatMode.none
            defaults.setValue(2, forKey: defaultsKeys.repeatSegment)
        }
    }
    
    @IBAction func audioPlayerEndTouched(_ sender: UISlider) {
        if player.playbackState == .playing {
            player.pause()
            //UIApplication.shared.isIdleTimerDisabled = true
            //isPlaying = true
        }
        else {
            //isPlaying = false
        }
        player.currentPlaybackTime = TimeInterval(audioPlaybackSlider.value)
        
        if player.playbackState != .playing {
            player.play()
            //UIApplication.shared.isIdleTimerDisabled = false
        }
        
        isAutoUpdatingPlayback = true
        //print("end")
    }
    
    @IBAction func musicSourceChanged(_ sender: UISegmentedControl) {
        if sourceSegment?.selectedSegmentIndex == 0 { //Songs
            self.songSlider.maximumValue = Float(self.songs.count)
            songSlider.title = "Songs"
            
            audioPlaybackSlider.isHidden = false
            lblPlaybackCurrent.isHidden = false
            lblPlaybackETA.isHidden = false
            
            defaults.setValue(0, forKey: defaultsKeys.sourceSegment)
        }
        else if sourceSegment?.selectedSegmentIndex == 1 { //Playlists
            songSlider.title = "Playlists"
            if self.songSlider.maximumValue == Float(songs.count) {
                lastSelectedSongIndex = Int(songSlider.value)
            }
            self.songSlider.maximumValue = Float(self.playlists.count)
            
            audioPlaybackSlider.isHidden = true
            lblPlaybackCurrent.isHidden = true
            lblPlaybackETA.isHidden = true
            
            defaults.setValue(1, forKey: defaultsKeys.sourceSegment)
        }
        else if sourceSegment?.selectedSegmentIndex == 2 { //Albums
            songSlider.title = "Albums"
            if self.songSlider.maximumValue == Float(songs.count) {
                lastSelectedSongIndex = Int(songSlider.value)
            }
            self.songSlider.maximumValue = Float(self.albums.count)
            
            audioPlaybackSlider.isHidden = true
            lblPlaybackCurrent.isHidden = true
            lblPlaybackETA.isHidden = true
        }
        
        if lastSelectedSongIndex != 0 && sourceSegment?.selectedSegmentIndex == 0 {
            songSlider.setValue(Float(lastSelectedSongIndex), animated: true)
        }
        else if sourceSegment?.selectedSegmentIndex == 1 {
            songSlider.setValue(1, animated: true)
        }
        else if sourceSegment?.selectedSegmentIndex == 2 {
            songSlider.setValue(1, animated: true)
        }
        
        self.carouselView.reloadData()
    }
    
    
    //MARK: Private Methods
    func buildCustomAlbumArt(song: MPMediaItem) -> UIImage {
        //Song have no album art so we need to creat our own
        let albumArtView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 360, height: 360))
        
        let background: UIImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 360, height: 360))
        background.image = #imageLiteral(resourceName: "noneart")
        
        let lblTitle: UILabel = UILabel(frame: CGRect(x: 40, y: 50, width: 280, height: 140))
        lblTitle.font = UIFont(name: "Chalkduster", size: 30.0)
        lblTitle.textColor = .yellow  //UIColor(red: 286, green: 498, blue: 504)
        lblTitle.numberOfLines = 3
        lblTitle.text = song.title ?? "No Name"
        lblTitle.textAlignment = .center
        
        let lblArtist: UILabel = UILabel(frame: CGRect(x: 20, y: 254, width: 320, height: 70))
        lblArtist.translatesAutoresizingMaskIntoConstraints = false
        lblArtist.font = UIFont(name: "Copperplate", size: 30.0)
        lblArtist.textColor = .white
        lblArtist.text = song.artist ?? "Various Artists"
        lblArtist.textAlignment = .center
        
        background.addSubview(lblTitle)
        background.addSubview(lblArtist)
        
        albumArtView.addSubview(background)
        albumArtView.prepareForInterfaceBuilder()
        
        return UIImage(view: albumArtView)
    }
    
    func setupLikes() {
        /*
         var temporarySavedSongIDs: [LikesArray] = []
         
         for _ in 0..<songs.count {
         likes.append(true)
         temporarySavedSongIDs.append(LikesArray(ID: nil, isLiked: true)!)
         }
         
         for i in 0..<savedSongIDs.count {
         if let savedID = savedSongIDs[i].ID {
         if userSongIDs.contains(savedID) {
         let index = userSongIDs.index(of: savedID)
         likes[index!] = savedSongIDs[i].isLiked
         temporarySavedSongIDs[index!] = savedSongIDs[i]
         }
         }
         }
         
         savedSongIDs = temporarySavedSongIDs*/
        
        for i in 0..<savedSongIDs.count {
            if let savedSongID = savedSongIDs[safe: i] {
                likes.append(savedSongID.isLiked)
            }
            else { printIndexError() }
        }
    }
    
    func likeIt() {
        print("I love me")
        
        if let isLiked = likes[safe: carouselView.currentItemIndex] {
            if isLiked == true {
                likes[carouselView.currentItemIndex] = false
                songSlider.icon = #imageLiteral(resourceName: "disliked")
                if let _ = savedSongIDs[safe: carouselView.currentItemIndex] {
                    savedSongIDs[carouselView.currentItemIndex].isLiked = false
                }
                else {printIndexError()}
            }
            else {
                likes[carouselView.currentItemIndex] = true
                songSlider.icon = #imageLiteral(resourceName: "liked")
                if let _ = savedSongIDs[safe: carouselView.currentItemIndex] {
                    savedSongIDs[carouselView.currentItemIndex].isLiked = true
                }
                else {printIndexError()}
            }
            
            saveLikesArray()
        }
        else {
            printIndexError()
        }
    }
    
    private func saveLikesArray() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(savedSongIDs, toFile: LikesArray.ArchiveURL.path)
        if isSuccessfulSave {
            os_log("Likes successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save likes...", log: OSLog.default, type: .error)
        }
    }
    
    private func loadSavedLikesArray() -> [LikesArray]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: LikesArray.ArchiveURL.path) as? [LikesArray]
    }
    
    func toPlayingSong(sender: UILongPressGestureRecognizer) {
        if let nowPlayingItem = self.player.nowPlayingItem {
            //lblCurrentlyPlaying.text = "Playing: \(nowPlayingItem.title ?? "none")"
            
            if let value = songs.index(of: nowPlayingItem) {
                if value == carouselView.currentItemIndex {
                    SCLAlertView().showTitle(
                        "Looking for me?", // Title of view
                        subTitle: "I'm in front of you 😜.", // String of view
                        duration: 5.0, // Duration to show before closing automatically, default: 0.0
                        completeText: "Oh man 😛", // Optional button value, default: ""
                        style: .success, // Styles - see below.
                        colorStyle: 0xA429FF,
                        colorTextButton: 0xFFFFFF
                    )
                }
                else {
                    songSlider.setValue(Float(value + 1), animated: false)
                    
                    //toLyricVC()
                }
            }
            else {
                print("error baby")
            }
        }
    }
    
    func songSwipe(sender: UISwipeGestureRecognizer) {
        if sender.direction == .right {
            if songSlider.value == songSlider.maximumValue {
                songSlider.setValue(songSlider.minimumValue, animated: true)
            }
            else {
                songSlider.setValue(Float(Int(songSlider.value) + 1), animated: true)
            }
        }
        else if sender.direction == .left {
            if songSlider.value == songSlider.minimumValue {
                songSlider.setValue(songSlider.maximumValue, animated: true)
            }
            else {
                songSlider.setValue(Float(Int(songSlider.value) - 1), animated: true)
            }
        }
    }
    
    func updateNowPlayingItem() {
        print("updateNowPlayingItem")
        
        if sourceSegment?.selectedSegmentIndex == 0 { //Songs
            if let nowPlayingItem = self.player.nowPlayingItem { //Get current playing song
                
                if let value = songs.index(of: nowPlayingItem) {
                    
                    if let title = songTitles[safe: value] {
                        if let artist = songArtists[safe: value] {
                            lblTitleSong.text = "\(title) - \(artist)"
                        }else {
                            printIndexError()
                        }
                    }
                    else{printIndexError()}
                    
                    //Automatic scroll to current playing song when song playing changed
                    songSlider.setValue(Float(value + 1), animated: false)
                    
                    //Change maximum value of slider
                    audioPlaybackSlider.maximumValue = Float(nowPlayingItem.playbackDuration)
                    
                    //Set currentPlaying
                    curPlayingSong = value
                    
                    //Set up like view in songSlider
                    if !likes.isEmpty {
                        if let isLiked = likes[safe: value] {
                            if isLiked == true {
                                songSlider.icon = #imageLiteral(resourceName: "liked")
                            }
                            else if isLiked == false {
                                songSlider.icon = #imageLiteral(resourceName: "disliked")
                            }
                        }
                        else {
                            printIndexError()
                        }
                    }
                    
                    if let title = songTitles[safe: value] {
                        lblCurrentlyPlaying.text = "Playing: \(title)" //Change current
                    }
                }
                else {
                    print("This is impossible, yet possible")
                }
                
                /*
                 if isShuffling {
                 if currentShuffledIndex == shuffledMedium.count - 1 {
                 //Stop player when done?
                 if player.playbackState == .playing {
                 player.stop()
                 UIApplication.shared.isIdleTimerDisabled = true
                 }
                 
                 //Enable back scrolling ability
                 self.carouselView.isScrollEnabled = true
                 self.songSlider.isUserInteractionEnabled = true
                 self.isShuffling = false
                 }
                 else {
                 currentShuffledIndex += 1 //Start with second song
                 }
                 
                 if let value = songs.index(of: nowPlayingItem) {
                 songSlider.setValue(Float(value + 1), animated: false)
                 curPlayingSong = value
                 }
                 else {
                 print("error baby")
                 }
                 }
                 else{
                 if let value = songs.index(of: nowPlayingItem) {
                 songSlider.setValue(Float(value + 1), animated: false)
                 }
                 else {
                 print("error baby")
                 }
                 }*/
            }
            else {
                print("No song is running")
            }
        }
        else { //Lists or albums
            if let nowPlayingItem = self.player.nowPlayingItem {
                lblCurrentlyPlaying.text = "Playing: \(nowPlayingItem.title ?? "none")"
            }
        }
        /*
         else if sourceSegment?.selectedSegmentIndex == 1 { //Playlists
         if let nowPlayingItem = self.player.nowPlayingItem {
         lblCurrentlyPlaying.text = "Playing: \(nowPlayingItem.title ?? "none")"
         }
         }
         else if sourceSegment?.selectedSegmentIndex == 2 { //Albums
         if let nowPlayingItem = self.player.nowPlayingItem {
         lblCurrentlyPlaying.text = "Playing: \(nowPlayingItem.title ?? "none")"
         }
         }
         
         //SAME*/
    }
    
    func updateStartup() {
        if player.playbackState == .playing {
            if let nowPlayingItem = self.player.nowPlayingItem {
                lblCurrentlyPlaying.text = "Playing: \(nowPlayingItem.title ?? "none")"
            }
        }
    }
    
    func updateAudioPlaybackSlider() {
        if isAutoUpdatingPlayback {
            if player.playbackState == .playing {
                //Update audio slider value
                audioPlaybackSlider.value = Float(player.currentPlaybackTime)
                
                let formatter = DateComponentsFormatter()
                formatter.unitsStyle = .positional
                formatter.allowedUnits = [.minute, .second ]
                formatter.zeroFormattingBehavior = [ .pad ]
                
                //Update playing time label
                let curDur: TimeInterval = player.currentPlaybackTime // Song's current time
                lblPlaybackCurrent.text = formatter.string(from: curDur)
                
                let remDur: TimeInterval = TimeInterval(Int(audioPlaybackSlider.maximumValue) - Int(player.currentPlaybackTime))
                lblPlaybackETA.text = "-\(formatter.string(from: remDur)!)"
            }
        }
    }
    
    func handleSwipes(sender: UISwipeGestureRecognizer) {
        if sourceSegment?.selectedSegmentIndex == 0 { //Songs
            if (sender.direction == .up) {
                //print("Swipe Up")
                
                SCLAlertView().showTitle(
                    "Shuffling 🎧", // Title of view
                    subTitle: "🎧 All songs are now playing shuffely 🎧.", // String of view
                    duration: 5.0, // Duration to show before closing automatically, default: 0.0
                    completeText: "OK", // Optional button value, default: ""
                    style: .success, // Styles - see below.
                    colorStyle: 0xA429FF,
                    colorTextButton: 0xFFFFFF
                )
                
                //Set back the tracking system
                //currentShuffledIndex = 0
                
                //Stop any playing song
                player.stop()
                //UIApplication.shared.isIdleTimerDisabled = true
                
                //self.player.shuffleMode = .songs
                shuffleSongs()
                isShuffling = true
                
                let shuffledMedia = MPMediaItemCollection(items: shuffledMedium)
                self.player.setQueue(with: shuffledMedia)
                
                
                //for shuffledMed in shuffledMedium {
                //print(shuffledMed.title ?? "No name")
                //}
                
                self.player.play()
                //UIApplication.shared.isIdleTimerDisabled = false
            }
            
            if (sender.direction == .down) {
                //print("Swipe down")
                
                //Stop player
                if player.playbackState == .playing {
                    player.stop()
                    //UIApplication.shared.isIdleTimerDisabled = true
                }
                
                //Enable back scrolling ability
                self.carouselView.isScrollEnabled = true
                self.songSlider.isUserInteractionEnabled = true
                self.isShuffling = false
                
            }
        }
        else if sourceSegment?.selectedSegmentIndex == 1 { //Playlists
            if sender.direction == .left {
                //print("Swipe Left")
                
                SCLAlertView().showTitle(
                    "😬", // Title of view
                    subTitle: "Nothing is implemented for this action 😬.", // String of view
                    duration: 3.0, // Duration to show before closing automatically, default: 0.0
                    completeText: "OK", // Optional button value, default: ""
                    style: .notice, // Styles - see below.
                    colorStyle: 0xA429FF,
                    colorTextButton: 0xFFFFFF
                )
            }
            else if sender.direction == .right {
                //print("Swipe Right")
                
                //Stop Player
                if player.playbackState == .playing {
                    player.stop()
                    //UIApplication.shared.isIdleTimerDisabled = true
                }
            }
        }
        else if sourceSegment?.selectedSegmentIndex == 2 { //Albums
            if sender.direction == .left {
                //print("Swipe Left")
                
                SCLAlertView().showTitle(
                    "😬", // Title of view
                    subTitle: "Nothing is implemented for this action 😬.", // String of view
                    duration: 3.0, // Duration to show before closing automatically, default: 0.0
                    completeText: "OK", // Optional button value, default: ""
                    style: .notice, // Styles - see below.
                    colorStyle: 0xA429FF,
                    colorTextButton: 0xFFFFFF
                )
            }
            else if sender.direction == .right {
                //print("Swipe Right")
                
                //Stop Player
                if player.playbackState == .playing {
                    player.stop()
                    //UIApplication.shared.isIdleTimerDisabled = true
                }
            }
        }
    }
    
    func shuffleSongs() {
        var chosenValue: [Int] = []
        
        chosenValue.removeAll()
        shuffledMedium.removeAll()
        
        //Let the first item is the current index song
        if let isLiked = likes[safe: Int(songSlider.value - 1)] {
            if isLiked == true {
                shuffledMedium.append(songs[Int(songSlider.value - 1)])
                //print("check \(Int(songSlider.value - 1))")
                //print("check \(songs[Int(songSlider.value - 1)].title!)")
                chosenValue.append(Int(songSlider.value - 1))
            }
        }
        else {
            printIndexError()
        }
        
        var songsToShuffle = 0
        for i in 0..<likes.count {
            if let isLiked = likes[safe: i] {
                if isLiked == true {
                    songsToShuffle += 1
                }
            }
            else {
                printIndexError()
            }
        }
        
        //Random number (index) and set the song with the randomed index
        for _ in 0...10000 {
            let random = Int(arc4random_uniform(UInt32(songs.count)))
            
            if !chosenValue.contains(random) {
                
                if let isLiked = likes[safe: random] {
                    if isLiked == true {
                        shuffledMedium.append(songs[random])
                        chosenValue.append(random)
                    }
                }
                else {
                    printIndexError()
                }
            }
            
            if chosenValue.count == songsToShuffle - 1 {
                break
            }
        }
        
        for song in shuffledMedium {
            print("Shuffled: \(song.title ?? "No name")")
        }
    }
    
    func prepareAllSong() {
        var songsToShuffle = 0
        for i in 0..<likes.count {
            if let isLiked = likes[safe: i] {
                
                if isLiked == true {
                    songsToShuffle += 1
                }
            }else{
                printIndexError()
            }
        }
        
        var chosenValue: [Int] = []
        
        chosenValue.removeAll()
        allSongsWithCustomStart.removeAll()
        
        //Let the first item is the current index song
        allSongsWithCustomStart.append(songs[Int(songSlider.value - 1)])
        chosenValue.append(Int(songSlider.value - 1))
        
        var currentTrack = Int(songSlider.value)
        //Add item in order
        for _ in 0...songs.count {
            currentTrack += 1
            
            if currentTrack >= songs.count { //Reach top
                if chosenValue.count == songsToShuffle - 1 {
                    break
                }
                else {
                    currentTrack = 1
                }
            }
            
            if !likes.isEmpty {
                if let isLiked = likes[safe: currentTrack - 1] {
                    if isLiked == true {
                        allSongsWithCustomStart.append(songs[currentTrack - 1])
                        chosenValue.append(currentTrack)
                    }
                }
                else {
                    printIndexError()
                }
            }
            else {
                allSongsWithCustomStart.append(songs[currentTrack - 1])
                chosenValue.append(currentTrack)
            }
        }
    }
    
    func displayMediaLibraryError() {
        var error: String
        switch MPMediaLibrary.authorizationStatus() {
        case .restricted:
            error = "Media library access restricted by corporate or parental settings"
        case .denied:
            error = "Media library access denied by user"
        default:
            error = "Unknown error"
        }
        
        let controller = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(controller, animated: true, completion: nil)
    }
    
    func toLyricVC() {
        if sourceSegment?.selectedSegmentIndex == 0 {
            
            
            //Show lyric for selected item (song)
            if let lyric = lyrics[safe: carouselView.currentItemIndex] {
                print("lyric: \(lyric)")
                if lyric.isEmpty {
                    if lyric == "No lyrics" {
                        printNoLyric()
                    }
                    else {
                        printNoLyric()
                    }
                }
                else {
                    //Set value for wanted index of lyric
                    if let nowPlayingItem = self.player.nowPlayingItem {
                        if let value = songs.index(of: nowPlayingItem) {
                            if value != carouselView.currentItemIndex {
                                defaults.set(carouselView.currentItemIndex, forKey: defaultsKeys.lyricForIndex)
                                defaults.set(true, forKey: defaultsKeys.shouldOpenLyricNotNowPlaying)
                            }
                            else {
                                defaults.set(false, forKey: defaultsKeys.shouldOpenLyricNotNowPlaying)
                            }
                        }
                    }
                    
                    //Open LyricsVC
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let controller: UIViewController = storyboard.instantiateViewController(withIdentifier: "LyricsVC") as UIViewController
                    present(controller, animated: true, completion: nil)
                }
            }
            else {
                printIndexError()
            }
            
            
            /*
             //For current playing item (obsolute)
             if let nowPlayingItem = self.player.nowPlayingItem {
             if let value = songs.index(of: nowPlayingItem) {
             if lyrics[value].isEmpty || lyrics[value] == "No lyrics" {
             SCLAlertView().showTitle(
             "😬", // Title of view
             subTitle: "I don't have lyric for this song 😬.", // String of view
             duration: 10.0, // Duration to show before closing automatically, default: 0.0
             completeText: "Oh, too bad!", // Optional button value, default: ""
             style: .info, // Styles - see below.
             colorStyle: 0xA429FF,
             colorTextButton: 0xFFFFFF
             )
             }
             else {
             let storyboard = UIStoryboard(name: "Main", bundle: nil)
             let controller: UIViewController = storyboard.instantiateViewController(withIdentifier: "LyricsVC") as UIViewController
             present(controller, animated: true, completion: nil)
             }
             }
             }*/
        }
    }
    
    func printNoLyric() {
        SCLAlertView().showInfo(
            "😬", // Title of view
            subTitle: "I don't have lyric for this song 🤒.", // String of view
            closeButtonTitle: "Oh, too bad!", // Duration to show before closing automatically, default: 0.0
            duration: 10.0, // Optional button value, default: ""
            colorStyle: 0xA429FF, // Styles - see below.
            colorTextButton: 0xFFFFFF,
            circleIconImage: nil
        )
    }
    
    func toSettingsVC(gesture: UIGestureRecognizer) {
        
        if let _ = gesture.view as? UIImageView {
            print("toSettingsVC")
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller: UINavigationController = storyboard.instantiateViewController(withIdentifier: "SettingsTableVC") as! UINavigationController
            present(controller, animated: true, completion: nil)
        }
    }
    
    func printIndexError() {
        /*
         SCLAlertView().showError(
         "😬", // Title of view
         subTitle: "My index has just gone out of range 😬. This sometimes happen 🤒", // String of view
         closeButtonTitle: "Oh, too bad!", // Duration to show before closing automatically, default: 0.0
         duration: 10.0, // Optional button value, default: ""
         colorStyle: 0xA429FF, // Styles - see below.
         colorTextButton: 0xFFFFFF,
         circleIconImage: nil
         )*/
    }
    
    //MARK: iCarousel Methods
    func numberOfItems(in carousel: iCarousel) -> Int {
        //return the total number of items in the carousel
        //print("Songs: \(artworks.count)")
        if sourceSegment?.selectedSegmentIndex == 0 { //Songs
            return songs.count
        }
        else if sourceSegment?.selectedSegmentIndex == 1 { //Playlists
            return playlists.count
        }
        else if sourceSegment?.selectedSegmentIndex == 2 { //Albums
            return albums.count
        }
        return 0
    }
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        //Create a UIView
        
        var tempView = UIView()
        
        let isReflectionOn = self.defaults.bool(forKey: defaultsKeys.isReflectionOn)
        
        if isReflectionOn {
            tempView = ReflectionView(frame: CGRect(x: 0, y: 0, width: 180, height: 180))
        }
        else {
            tempView = UIView(frame: CGRect(x: 0, y: 0, width: 180, height: 180))
        }
        
        
        //let tempView = UIView(frame: CGRect(x: 0, y: 0, width: (self.carouselView.frame.width / 3 * 2) + 20, height: (self.carouselView.frame.width / 3 * 2) + 20))
        /* When battery low power mode is on or user settings
         let tempView = ReflectionView(frame: CGRect(x: 0, y: 0, width: (self.carouselView.frame.width / 3 * 2) + 20, height: (self.carouselView.frame.width / 3 * 2) + 20))*/
        tempView.setNeedsDisplay()
        
        //Create a UIImageView
        let frame = CGRect(x: 0, y: 0, width: 180, height: 180)
        
        //Create view for song that has not album art
        let albumArtView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 180, height: 180))
        albumArtView.layer.cornerRadius = 20
        albumArtView.layer.borderWidth = 3.0
        albumArtView.layer.borderColor = UIColor.white.cgColor
        albumArtView.clipsToBounds = true
        
        var imageView = AsyncImageView()
        
        if self.sourceSegment?.selectedSegmentIndex == 0 { //Songs
            
            imageView = AsyncImageView(image: self.artworks[index])
            /*
             if #imageLiteral(resourceName: "defaultPhoto") != artworks[index] {
             imageView = AsyncImageView(image: artworks[index])
             }
             else {
             //Song have no album art so we need to creat our own
             let background: UIImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 180, height: 180))
             background.image = #imageLiteral(resourceName: "noneart")
             
             let lblTitle: UILabel = UILabel(frame: CGRect(x: 16, y: 10, width: 170, height: 70))
             lblTitle.font = UIFont(name: "Chalkduster", size: 12.0)
             lblTitle.textColor = UIColor(red: 143, green: 249, blue: 252)
             lblTitle.numberOfLines = 3
             lblTitle.text = songTitles[index]
             lblTitle.contentMode = .center
             
             let lblArtist: UILabel = UILabel(frame: CGRect(x: 16, y: 127, width: 154, height: 35))
             lblArtist.font = UIFont(name: "Copperplate", size: 10.0)
             lblArtist.textColor = .white
             lblArtist.text = songArtists[index]
             lblArtist.contentMode = .center
             
             background.addSubview(lblTitle)
             background.addSubview(lblArtist)
             
             albumArtView.addSubview(background)
             }*/
        }
        else if self.sourceSegment?.selectedSegmentIndex == 1 { //Playlists
            imageView = AsyncImageView(image: self.playlistsRepresentativeImages[index])
        }
        else if self.sourceSegment?.selectedSegmentIndex == 2 { //Albums
            imageView = AsyncImageView(image: self.albumRepresentativeImages[index])
        }
        imageView.frame = frame
        imageView.contentMode = .scaleToFill
        imageView.layer.cornerRadius = 20
        imageView.layer.borderWidth = 3.0
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.clipsToBounds = true
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.toLyricVC))
        tempView.addGestureRecognizer(longPress)
        
        //Set the image of artworks to the imageView and add it to the tempView
        AsyncImageLoader.shared().cancelLoadingImages(forTarget: view)
        
        /*
         //Create like view
         let likeView = UIImageView(frame: CGRect(x: -15, y: -15, width: 30, height: 30))
         likeView.image = #imageLiteral(resourceName: "liked")
         likeView.contentMode = .scaleToFill
         likeView.backgroundColor = .black
         likeView.layer.cornerRadius = 10
         likeView.clipsToBounds = false
         
         let touchLikeBtn = UITapGestureRecognizer(target: self, action: #selector(likeIt))
         likeView.addGestureRecognizer(touchLikeBtn)*/
        
        /*
         if #imageLiteral(resourceName: "defaultPhoto") != artworks[index] {
         tempView.addSubview(imageView)
         }
         else {
         tempView.addSubview(albumArtView)
         }*/
        tempView.addSubview(imageView)
        
        //print("pass3")
        
        return tempView
        
    }
    
    func carousel(_ carousel: iCarousel, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        switch option {
        case .spacing:
            return value * 5.0
            //case .fadeMin:
            //    return -0.2
            //case .fadeMax:
            //    return 0.2
            //case .fadeRange:
        //  return 0.2
        default:
            return value
        }
    }
    
    func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
        if sourceSegment?.selectedSegmentIndex == 0 { //Songs
            
            //print("currentSelection: \(currentSelection)")
            /*
             if playingIndex != curPlayingSong || curPlayingSong != carouselView.currentItemIndex {
             audioPlaybackSlider.maximumValue = Float(songs[carouselView.currentItemIndex].playbackDuration)
             }*/
            
            isShuffling = false //End shuffling
            
            if player.playbackState != .playing && curPlayingSong == carouselView.currentItemIndex {
                
                prepareAllSong()
                let media = MPMediaItemCollection(items: allSongsWithCustomStart)
                self.player.setQueue(with: media)
                
                player.play()
            }
            else if player.playbackState != .playing && curPlayingSong != carouselView.currentItemIndex {
                //I think this is perfect
                if repeatSegment.selectedSegmentIndex == 0 {
                    prepareAllSong()
                    
                    let media = MPMediaItemCollection(items: allSongsWithCustomStart)
                    
                    self.player.setQueue(with: media)
                }
                else {
                    if let song = MPMediaQuery.songs().items![safe: carouselView.currentItemIndex] {
                        let media = MPMediaItemCollection(items: [song])
                        
                        self.player.setQueue(with: media)
                    }
                }
                self.player.play()
                //UIApplication.shared.isIdleTimerDisabled = false
                ////////////////////////////////////////////////////
            }
            else if player.playbackState == .playing && curPlayingSong != carouselView.currentItemIndex {
                //I think this is perfect
                if repeatSegment.selectedSegmentIndex == 0 {
                    prepareAllSong()
                    
                    let media = MPMediaItemCollection(items: allSongsWithCustomStart)
                    
                    self.player.setQueue(with: media)
                }
                else {
                    if let song = MPMediaQuery.songs().items![safe: carouselView.currentItemIndex] {
                        let media = MPMediaItemCollection(items: [song])
                        
                        self.player.setQueue(with: media)
                    }
                }
                self.player.play()
                //UIApplication.shared.isIdleTimerDisabled = false
                ////////////////////////////////////////////////////
            }
            else if player.playbackState == .playing && curPlayingSong == carouselView.currentItemIndex {
                player.pause() //Pause if the song is playing and user tap on the playing song
                //UIApplication.shared.isIdleTimerDisabled = true
            }
        }
        else if sourceSegment?.selectedSegmentIndex == 1 { //Playlists
            if player.playbackState != .playing || curPlayingPlaylist != carouselView.currentItemIndex {
                
                let media = MPMediaItemCollection(items: playlists[carouselView.currentItemIndex].items)
                
                self.player.setQueue(with: media)
                self.player.play()
                //UIApplication.shared.isIdleTimerDisabled = false
                curPlayingPlaylist = carouselView.currentItemIndex
            }
            else {
                player.pause()
                //UIApplication.shared.isIdleTimerDisabled = true
            }
        }
        else if sourceSegment?.selectedSegmentIndex == 2 { //Albums
            if player.playbackState != .playing || curPlayingAlbum != carouselView.currentItemIndex {
                
                let media = MPMediaItemCollection(items: albums[carouselView.currentItemIndex].items)
                
                self.player.setQueue(with: media)
                self.player.play()
                //UIApplication.shared.isIdleTimerDisabled = false
                curPlayingAlbum = carouselView.currentItemIndex
            }
            else {
                player.pause()
                //UIApplication.shared.isIdleTimerDisabled = true
                
            }
        }
    }
    
    func carouselDidScroll(_ carousel: iCarousel) {
        if sourceSegment?.selectedSegmentIndex == 0 { //Songs
            if lastCarouselValueForSongs != (carouselView.currentItemIndex + 1) {
                //print(carouselView.currentItemIndex)
                //songSlider.value = Float(carouselView.currentItemIndex + 1)
                //print(songSlider.value)
                
                if songTitles.count != 0 && songArtists.count != 0 {
                    lblTitleSong.text
                        = "\(songTitles[carouselView.currentItemIndex]) - \(songArtists[carouselView.currentItemIndex])"
                }
                
                lastCarouselValueForSongs = carouselView.currentItemIndex + 1
            }
        }
        else if sourceSegment?.selectedSegmentIndex == 1 { //Playlists
            if lastCarouselValueForPlaylists != (carouselView.currentItemIndex + 1) {
                if playlistTitles.count != 0 {
                    lblTitleSong.text = "\(playlistTitles[carouselView.currentItemIndex])"
                }
            }
            
            lastCarouselValueForPlaylists = carouselView.currentItemIndex + 1
        }
        else if sourceSegment?.selectedSegmentIndex == 2 { //Albums
            if lastCarouselValueForAlbums != (carouselView.currentItemIndex + 1) {
                if albumTitles.count != 0 {
                    lblTitleSong.text = "\(albumTitles[carouselView.currentItemIndex])"
                }
            }
            
            lastCarouselValueForAlbums = carouselView.currentItemIndex + 1
        }
    }
    
    func carouselDidEndScrollingAnimation(_ carousel: iCarousel) {
        if sourceSegment?.selectedSegmentIndex == 0 { //Songs
            
            songSlider.setValue(Float(carouselView.currentItemIndex + 1), animated: false)
            
            /* This should never be implemented here
             if !isLikeds.isEmpty {
             if isLikeds[carouselView.currentItemIndex] == true {
             songSlider.icon = #imageLiteral(resourceName: "liked")
             }
             else {
             songSlider.icon = #imageLiteral(resourceName: "disliked")
             }
             }*/
            
            
            if !songs.isEmpty && player.playbackState != .playing{
                audioPlaybackSlider.maximumValue = Float(songs[carouselView.currentItemIndex].playbackDuration)
            }
            //if currentSelection != carouselView.currentItemIndex {
            //    audioPlaybackSlider.setValue(0, animated: true)}
            
            //for index in carouselView.indexesForVisibleItems {
            //    carouselView.reloadItem(at: index as! Int, animated: true)
            //}
            carouselView.reloadData()
            
        }
        else if sourceSegment?.selectedSegmentIndex == 1 { //Playlists
            
            
            songSlider.setValue(Float(carouselView.currentItemIndex + 1), animated: false)
            
            if playlists.count > 0 && player.playbackState != .playing {
                //Do nothing
            }
        }
        else if sourceSegment?.selectedSegmentIndex == 2 { //Albums
            songSlider.setValue(Float(carouselView.currentItemIndex + 1), animated: false)
            
            if albums.count > 0 && player.playbackState != .playing {
                //Do nothing
            }
        }
    }
}

// MARK: - CircularSliderDelegate
extension ViewController: CircularSliderDelegate {
    func circularSlider(_ circularSlider: CircularSlider, valueForValue value: Float) -> Float {
        if circularSlider == songSlider {
            if sourceSegment?.selectedSegmentIndex == 0 { //Songs
                if lastSongSliderValueForSongs != Int(floorf(value)) {
                    carouselView.scrollToItem(at: Int(floorf(value)) - 1, animated: true)
                    //print(Int(floorf(value)))
                    
                    lastSongSliderValueForSongs = Int(floorf(value))
                    
                    
                    if let title = songTitles[safe: Int(floorf(value)) - 1] {
                        if let artist = songArtists[safe: Int(floorf(value)) - 1] {
                            lblTitleSong.text = "\(title) - \(artist)"
                        }
                        else {
                            printIndexError()
                        }
                    }
                    else {
                        printIndexError()
                    }
                    
                    if !likes.isEmpty {
                        if let isLiked = likes[safe: Int(floorf(value)) - 1] {
                            if isLiked == true {
                                songSlider.icon = #imageLiteral(resourceName: "liked")
                            }
                            else if isLiked == false {
                                songSlider.icon = #imageLiteral(resourceName: "disliked")
                            }
                        }
                        else {
                            printIndexError()
                        }
                    }
                    //print("chang by me 1")
                    
                    if songs.count > 0 && player.playbackState != .playing {
                        if let song = songs[safe: Int(floorf(value)) - 1] {
                            audioPlaybackSlider.maximumValue = Float(song.playbackDuration)
                        }
                        else {
                            printIndexError()
                        }
                    }
                }
            }
            else if sourceSegment?.selectedSegmentIndex == 1 { //Playlists
                if lastSongSliderValueForPlaylists != Int(floorf(value)) {
                    carouselView.scrollToItem(at: Int(floorf(value)) - 1, animated: true)
                    
                    lastSongSliderValueForPlaylists = Int(floorf(value))
                    
                    if playlistTitles.count != 0 {
                        if let title = playlistTitles[safe: Int(floorf(value)) - 1] {
                            lblTitleSong.text = "\(title)"
                        }
                        else {
                            printIndexError()
                        }
                    }
                }
            }
            else if sourceSegment?.selectedSegmentIndex == 2 { //Albums
                if lastSongSliderValueForAlbums != Int(floorf(value)) {
                    carouselView.scrollToItem(at: Int(floorf(value)) - 1, animated: true)
                    
                    lastSongSliderValueForAlbums = Int(floorf(value))
                    
                    if albumTitles.count != 0 {
                        if let title = albumTitles[safe: Int(floorf(value)) - 1] {
                            lblTitleSong.text = "\(title)"
                        }
                    }
                }
            }
            
        }
        return floorf(value)
    }
}
