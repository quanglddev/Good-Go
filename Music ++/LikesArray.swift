//
//  LikesArray.swift
//  Music ++
//
//  Created by QUANG on 1/22/17.
//  Copyright © 2017 Q.U.A.N.G. All rights reserved.
//

import MediaPlayer
class LikesArray: NSObject, NSCoding {
    
    //MARK: Types
    struct PropertyKey {
        static let ID = "ID"
        static let isLiked = "isLiked"
    }
    
    //MARK: Properties
    var ID: MPMediaEntityPersistentID?
    var isLiked: Bool
    
    //MARK: Initialization
    init?(ID: MPMediaEntityPersistentID?, isLiked: Bool) {
        self.ID = ID
        self.isLiked = isLiked
    }
    
    //MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("LikesArrays")
    
    //MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(ID, forKey: PropertyKey.ID)
        aCoder.encode(isLiked, forKey: PropertyKey.isLiked)
    }

    required convenience init?(coder aDecoder: NSCoder) {
        // Because photo is an optional property of Task, just use conditional cast.
        let ID = aDecoder.decodeObject(forKey: PropertyKey.ID) as? MPMediaEntityPersistentID
        
        let isLiked = aDecoder.decodeBool(forKey: PropertyKey.isLiked)
        
        // Must call designated initializer.
        self.init(ID: ID, isLiked: isLiked)
    }
}
