//
//  LikeIt.swift
//  Music ++
//
//  Created by QUANG on 1/22/17.
//  Copyright © 2017 Q.U.A.N.G. All rights reserved.
//

import os.log
import MediaPlayer

class LikeIt: NSObject, NSCoding {
    
    //MARK: Types
    
    struct PropertyKey {
        static let ID = "ID"
        static let liked = "liked"
    }
    
    //MARK: Properties
    var ID: MPMediaEntityPersistentID
    var liked: Bool
    
    //MARK: Archiving Paths
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("LikeIt")
    
    
    //MARK: Initialization
    init?(ID: MPMediaEntityPersistentID, liked: Bool) {
        
        self.ID = ID
        self.liked = liked
    }

    //MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(ID, forKey: PropertyKey.ID)
        aCoder.encode(liked, forKey: PropertyKey.liked)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let ID = aDecoder.decodeObject(forKey: PropertyKey.ID) as? MPMediaEntityPersistentID else {
            os_log("Unable to decode ID.", log: OSLog.default, type: .debug)
            return nil
        }
        
        let liked = aDecoder.decodeBool(forKey: PropertyKey.liked)
        
        // Must call designated initializer.
        self.init(ID: ID, liked: liked)
    }
}
