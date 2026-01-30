//
//  PhotoRecognitionGameData.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import Foundation

/// Photo questions for the recognition game
/// Replace these with your actual photos and names
struct PhotoQuestion {
    let id: String
    let imageURL: URL?
    let correctName: String
    let imageName: String // For local assets
}

enum PhotoRecognitionGameData {
    /// Static photos with names for the recognition game
    /// Replace imageName with your actual asset names or use imageURL for remote images
    static let photos: [PhotoQuestion] = [
        PhotoQuestion(
            id: "photo1",
            imageURL: nil,
            correctName: "Albert Einstein",
            imageName: "einstein"
        ),
        PhotoQuestion(
            id: "photo2",
            imageURL: nil,
            correctName: "Mahatma Gandhi",
            imageName: "gandhi"
        ),
        PhotoQuestion(
            id: "photo3",
            imageURL: nil,
            correctName: "Marie Curie",
            imageName: "curie"
        ),
        PhotoQuestion(
            id: "photo4",
            imageURL: nil,
            correctName: "Nelson Mandela",
            imageName: "mandela"
        ),
        PhotoQuestion(
            id: "photo5",
            imageURL: nil,
            correctName: "Mother Teresa",
            imageName: "teresa"
        ),
    ]
}
