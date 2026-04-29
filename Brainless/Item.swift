//
//  Item.swift
//  Brainless
//
//  Created by Abdullah Raza on 29/04/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
