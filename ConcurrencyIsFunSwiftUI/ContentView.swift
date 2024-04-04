//
//  ContentView.swift
//  ConcurrencyIsFunSwiftUI
//
//  Created by Vitor Kalil on 26/03/24.
//
import SwiftUI
import PhotosUI
import Foundation

struct GPTAPIResponse: Codable {
    let id: String
    //let object: String
    //let created: Int
    //let model: String
    //let choices: [Choice]
}
struct Choice: Codable {
    let message: Message
    let index: Int
    let finish_reason: String
}

struct Message: Codable {
    let role: String
    let content: String
}

@MainActor class ContentViewModel: ObservableObject{
    //
    // So, why MainActor? This macro was added here due to an issue that happened before adding it. One cannot simply change a Published variable from any thread other then the main Thread. The Main Actor (an already-made globalActor) macro ensures that the code is run on the main Thread, avoiding data races.
    @Published var myPlant = Plant()

    let plantNetKey:String = ""
    /*
     let headers = [
         "content-type": "application/json",
         "X-RapidAPI-Key": "",
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
        let request = NSMutableURLRequest(url: NSURL(string: "https://my-api.plantnet.org/v2/identify/all?include-related-images=true&no-reject=false&lang=en&api-key=" + plantNetKey)! as URL)
        request.httpMethod = "POST"
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        postData.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        postData.append("Content-Disposition: form-data; name=\"images\"; filename=\"image.png\"\r\n".data(using: .utf8)!)
        postData.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        postData.append(sentImage.pngData()!)

        postData.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = postData as Data?
        
        do {
            let (data,_) = try await URLSession.shared.data(for: request as URLRequest)
            
            // since this is a asynchronous function, I need to wait for the result. To do that, we use the keyword await
            //guard let data:Data? = data else {return}
            
            let plants = try JSONDecoder().decode(PlantJSONModel.self, from:data)
           await MainActor.run(body: {
               myPlant.plantCommonName = plants.results[0].species.commonNames[0]
               myPlant.plantAllCommonNames = plants.results[0].species.commonNames
               myPlant.plantScientificName = plants.results[0].species.scientificName
               myPlant.plantScientificNameWithoutAuthor = plants.results[0].species.scientificNameWithoutAuthor
               myPlant.plantFamily = plants.results[0].species.family.scientificName
        for image in plants.results[0].images{
                    myPlant.plantSimilarImagesUrls.append(image.url.m)
                }
            })
            
            
            /*
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
                
                        }*/
        } catch  {
            print(error.localizedDescription)
            throw error
        }
    }
    
    func requestChatGPT() async throws{
        
        let apiKey = ""
        let gptURL = "https://api.openai.com/v1/chat/completions"
        let prompt=""
        let request = NSMutableURLRequest(url: NSURL(string: "https://api.openai.com/v1/chat/completions")! as URL)
        // Creamos una solicitud HTTP POST
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Definimos el cuerpo de la solicitud como un diccionario y lo convertimos a datos JSON
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "?"],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": NSNumber(value: 10)
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        do {
            let (data,_) = try await URLSession.shared.data(for: request as URLRequest)
//            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
//            if let responseJSON = responseJSON as? [String: Any] {
//                            print("-----2> responseJSON: \(responseJSON)")
//                        }
            let GPTResponse = try JSONDecoder().decode(GPTAPIResponse.self, from:data)
            print(GPTResponse)
        } catch  {
            print(error.localizedDescription)
            throw error
        }
    }
    
}

struct ContentView: View {
    
    @State private var selectedItem: PhotosPickerItem?
    @State var image: UIImage?
    @State var isLoading:Bool = false
    @State var showPlantDetailedView:Bool = false
    @State var myColor:Color?
    
    @StateObject var viewModel:ContentViewModel = ContentViewModel()
    

    
   
    var body: some View {
        
        VStack {
            Button{
                myColor = myColor == .accentColor ? .gray : .accentColor
            } label: {
                Image(systemName: "camera.macro").resizable().frame(width:50,height:50).foregroundColor(.white).padding(15).background(Circle()
                    .fill(myColor ?? .gray)
                    .shadow(radius: 5))
            }
            
            Spacer()
            if isLoading {
                ProgressView().tint(.accentColor).scaleEffect(2).padding()
                Spacer()
            }
            PhotosPicker("Select an image", selection: $selectedItem, matching: .images).foregroundColor(.white).padding(15).background(RoundedRectangle(cornerRadius: 10)
                .fill(Color.accentColor)
                .shadow(radius: 5))
                .onChange(of: selectedItem) {
                    Task {
                        try? await viewModel.requestChatGPT()
                        if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                            image = UIImage(data: data)
                            isLoading = true
                            try await viewModel.requestRecognitionFormFormat(sentImage: image!)
                            isLoading = false
                            showPlantDetailedView = true
                        }
 
                    }
                }
            
            
        }
        .padding().sheet(isPresented:$showPlantDetailedView) {
            PlantDetailedView(plant:viewModel.myPlant,mainImage: Image(uiImage: image!))
        }
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
