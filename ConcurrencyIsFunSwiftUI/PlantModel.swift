//
//  PlantModel.swift
//  ConcurrencyIsFunSwiftUI
//
//  Created by Vitor Kalil on 01/04/24.
//

import SwiftUI

struct Plant {
    var plantCommonName:String = ""
    var plantAllCommonNames:[String] = []
    var plantScientificName:String = ""
    var plantScientificNameWithoutAuthor:String = ""
    var plantFamily:String = ""
    var plantSimilarImagesUrls:[String] = []
}
struct PlantJSONModel: Codable {
    let bestMatch: String
    let language: String
    let preferedReferential: String
    let results: [PlantResult]
    let version: String
}

struct PlantResult: Codable {
    let images: [plantImage]
    //let score: Float
    let species: Species
}

// Added this Identifiable and the id var to be able to pass it to the ForEach on the ContentView function requestRecognitionFormFormat
struct plantImage: Codable {
    //var id = UUID()
    let author: String
    let citation: String
    let license: String
    let organ: String
    let url: PlantImageURL
}

struct PlantImageURL: Codable {
    let m: String
    let o: String
    let s: String
}

struct Species: Codable {
    let commonNames: [String]
    let family: ScientificName
    let genus: ScientificName
    let scientificName: String
    let scientificNameAuthorship: String
    let scientificNameWithoutAuthor: String
}

struct ScientificName: Codable {
    let scientificName: String
    let scientificNameAuthorship: String
    let scientificNameWithoutAuthor: String
}
