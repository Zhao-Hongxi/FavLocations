//
//  Keychain.swift
//  FavLocations
//
//  Created by ivan on 2021/12/16.
//

import Foundation
import KeychainSwift

class Keychain{
    var _key = KeychainSwift()
    
    var key : KeychainSwift {
        get{
            return _key
        }
        set {
            _key = newValue
        }
    }
}
