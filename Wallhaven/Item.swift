//
//  Item.swift
//  Wallhaven
//
//  Created by 星星魔法术 on 15/06/2026.
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
