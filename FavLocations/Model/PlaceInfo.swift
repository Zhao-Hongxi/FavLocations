//
//  PlaceInfo.swift
//  FavLocations
//
//  Created by ivan on 2021/12/15.
//

import Foundation
import RealmSwift

class PlaceInfo : Object {
    @objc dynamic var placeDescription : String = ""
    @objc dynamic var place_id : String = ""
    @objc dynamic var main_text : String = ""
    @objc dynamic var secondary_text : String = ""
    
    override static func primaryKey() -> String? {
        return "place_id"
    }
}
