//
//  PlantDetailedView.swift
//  ConcurrencyIsFunSwiftUI
//
//  Created by Vitor Kalil on 01/04/24.
//

import SwiftUI

struct PlantDetailedView: View {
    @State var plant:Plant
    @State var mainImage:Image
    var body: some View {
        ScrollView{
            ParallaxEffect(image: mainImage)
            PlantDataView(plant:plant,urls:plant.plantSimilarImagesUrls).padding()
        }
    }
}
/*
#Preview {
    PlantDetailedView()
}*/

struct ParallaxEffect: View {
    var image:Image
    var body: some View {
        GeometryReader{ geometry in
            let offsetY = geometry.frame(in: .global).minY
            let isScrolled = offsetY > 0
            Spacer()
                .frame(height:isScrolled ? 300 + offsetY : 300)
                .background{
                        image
                            .resizable()
                            .scaledToFill()
                            .offset(y:isScrolled ? -offsetY : 0)
                            .scaleEffect(isScrolled ? offsetY / 2000 + 1 : 1)
                            .blur(radius:isScrolled ? offsetY / 80: 0)
                }
        }.frame(height:400)
    }
}
struct PlantDataView:View {
    @StateObject var viewModel = PlantDataViewModel()
    @State var plant:Plant
    @State var urls:[String]
    var body: some View {
        VStack(alignment: .leading){
            Spacer()
            Text(plant.plantCommonName).font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
            Spacer()
            Text("Family Name: " + plant.plantFamily).font(.headline)
            Text("Scientific Name: " + plant.plantScientificName).font(.headline)
            Text("Scientific Name w/o Author: " + plant.plantScientificNameWithoutAuthor).font(.headline)
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            ScrollView(.horizontal){
                HStack{
                    if let images = viewModel.plantImages{
                        ForEach(images,id:\.self){ image in
                            Image(uiImage: image).resizable().frame(width: 300,height:300)
                        }
                    } else{
                        ProgressView().scaleEffect(2).padding().frame(width:200,height: 200)
                        ProgressView().scaleEffect(2).padding().frame(width:200,height: 200)
                        ProgressView().scaleEffect(2).padding().frame(width:200,height: 200)
                        ProgressView().scaleEffect(2).padding().frame(width:200,height: 200)
                    }
                }
            }
            
        }.task{
            try? await viewModel.fetchimagesWithTaskGroup(plantImageUrls: plant.plantSimilarImagesUrls)
        }
    }
}

@MainActor class PlantDataViewModel:ObservableObject{
    @Published var plantImages:[UIImage]?
    
    func fetchimagesWithTaskGroup(plantImageUrls:[String]) async throws{
        print(plantImageUrls)
        try await withThrowingTaskGroup(of: UIImage.self){ group in
            var images: [UIImage] = []
            images.reserveCapacity(plantImageUrls.count)
            for urlString in plantImageUrls {
                group.addTask{
                    try await self.downloadWithAsync(url:URL(string: urlString)!)
                }
            }
            for try await image in group {
                images.append(image)
            }
            self.plantImages = images
        }
    }
    
    func downloadWithAsync(url:URL) async throws -> UIImage{
        do {
            let (data,_) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)!
        } catch  {
            throw error
        }
    }
}
