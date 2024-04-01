//
//  Item.swift
//  ConcurrencyIsFunSwiftUI
//
//  Created by Vitor Kalil on 26/03/24.
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
