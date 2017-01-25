//
//  Collection+SafeIndex.swift
//  Music ++
//
//  Created by QUANG on 1/25/17.
//  Copyright © 2017 Q.U.A.N.G. All rights reserved.
//

extension Collection where Indices.Iterator.Element == Index {
    
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Generator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
