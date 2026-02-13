//
//  UserPhoto.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import Foundation
import SwiftData
import UIKit

/// User-uploaded photo with name for recognition game
@Model
final class UserPhoto {
    var id: String
    var imageData: Data? // Store image as Data
    var correctName: String
    var timestamp: Date
    var isActive: Bool // Whether to use in game
    
    init(
        id: String = UUID().uuidString,
        imageData: Data? = nil,
        correctName: String,
        timestamp: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.imageData = imageData
        self.correctName = correctName
        self.timestamp = timestamp
        self.isActive = isActive
    }
    
    /// Convert Data to UIImage for display
    var uiImage: UIImage? {
        guard let imageData = imageData else { return nil }
        return UIImage(data: imageData)
    }
}
