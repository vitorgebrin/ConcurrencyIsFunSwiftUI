//
//  ContentView.swift
//  ConcurrencyIsFunSwiftUI
//
//  Created by Vitor Kalil on 26/03/24.
//
import SwiftUI
import PhotosUI
import Foundation

@MainActor class ContentViewModel: ObservableObject{
    //
    // So, why MainActor? This macro was added here due to an issue that happened before adding it. One cannot simply change a Published variable from any thread other then the main Thread. The Main Actor (an already-made globalActor) macro ensures that the code is run on the main Thread, avoiding data races.
    @Published var plantCommonName:String = ""
    @Published var plantScientificName:String = ""
    @Published var plantFamily:String = ""
    @Published var plantSimilarImagesUrls:[String] = []

    let plantNetKey:String = "2b10wldC1TVzsYo4ztrx741Kj"
    /*
     let headers = [
         "content-type": "application/json",
         "X-RapidAPI-Key": "bf0afc85femshc4d4654322dbeb8p1a480ejsn76f7e2939162",
         "X-RapidAPI-Host": "plant-recognizer.p.rapidapi.com"
     ]
    func requestRecognitionBase64(sentImage:UIImage) async throws{
        let parameters = ["file": sentImage.base64] as [String : Any]
        let postData = try? JSONSerialization.data(withJSONObject: parameters, options: [])

        let request = NSMutableURLRequest(url: NSURL(string: "https://plant-recognizer.p.rapidapi.com/identify_image")! as URL,cachePolicy: .useProtocolCachePolicy,timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = postData as Data?
        do {
            let (data,response) = try await URLSession.shared.data(for: request as URLRequest)
            // since this is a asynchronous function, I need to wait for the result. To do that, we use the keyword await
            guard let data:Data? = data else {return}
            let responseJSON = try? JSONSerialization.jsonObject(with: data!, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                            print("-----2> responseJSON: \(responseJSON)")
                        }
        } catch  {
            throw error
        }
    }
    */
    
    func requestRecognitionFormFormat(sentImage:UIImage) async throws{
        
        let boundary = UUID().uuidString
        var postData = Data()
        let request = NSMutableURLRequest(url: NSURL(string: "https://my-api.plantnet.org/v2/identify/all?include-related-images=false&no-reject=false&lang=en&api-key=" + plantNetKey)! as URL)
        request.httpMethod = "POST"
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        postData.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        postData.append("Content-Disposition: form-data; name=\"images\"; filename=\"image.png\"\r\n".data(using: .utf8)!)
        postData.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        postData.append(sentImage.pngData()!)

        postData.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = postData as Data?
        
        do {
            let (data,response) = try await URLSession.shared.data(for: request as URLRequest)
            // since this is a asynchronous function, I need to wait for the result. To do that, we use the keyword await
            //guard let data:Data? = data else {return}
            
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options:[])
            //print(((responseJSON! as AnyObject)["results"]! as! NSArray)[0])
            if let responseJSON = responseJSON as? AnyObject{
                print("-----2> responseJSON: \(responseJSON)")
                if let results = responseJSON["results"] as? [AnyObject]{
                    
                    let first = results[0] as AnyObject
                    if let species = first["species"] as? AnyObject{
                        if let commonNames = species["commonNames"] as? [String]{
                            await MainActor.run(body:{ plantCommonName = commonNames[0]})
                            
                        }
                        if let familyNames = species["family"] as? AnyObject{
                            await MainActor.run(body:{ plantFamily = familyNames["scientificName"] as! String})
                        }
                        await MainActor.run(body:{ plantScientificName = species["scientificName"] as! String})
                    }
                    
                }
                
                        }
        } catch  {
            throw error
        }
    }
    
}

struct ContentView: View {
    
    @State private var selectedItem: PhotosPickerItem?
    @State var image: UIImage?
    @State var isLoading:Bool = false
    
    @StateObject var viewModel:ContentViewModel = ContentViewModel()
    

    
   
    var body: some View {
        VStack {
            PhotosPicker("Select an image", selection: $selectedItem, matching: .images)
                .onChange(of: selectedItem) {
                    Task {
                        if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                            image = UIImage(data: data)
                            isLoading = true
                            try await viewModel.requestRecognitionFormFormat(sentImage: image!)
                            isLoading = false
                        }
 
                    }
                }
            if isLoading {
                ProgressView().scaleEffect(2).padding()
            } else{
                VStack{
                    Image(uiImage: image ?? UIImage(systemName: "person")! ).resizable().frame(width:200,height: 200)
                    VStack(alignment: .leading){
                        Text("Plant Common Name: " + viewModel.plantCommonName)
                        Text("Plant Scientific Name: " + viewModel.plantScientificName)
                        Text("Plant's Family: " + viewModel.plantFamily)
                    }
                }.padding()
            }
            
        }
        .padding()
    }
    
    
}

#Preview {
    ContentView()
}

extension UIImage {
    var base64: String? {
        self.jpegData(compressionQuality: 1)?.base64EncodedString()
    }
}
