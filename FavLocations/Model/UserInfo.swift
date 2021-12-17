//
//  UserInfo.swift
//  FavLocations
//
//  Created by ivan on 2021/12/16.
//

import Foundation
import RealmSwift

class UserInfo : Object {
    
    @objc dynamic var uid : String = ""
//    @objc dynamic var savedLocations : [PlaceInfo] = []
    // place id lists
    let savedLocations = List<String>()
    
    override static func primaryKey() -> String? {
        return "uid"
    }
}
