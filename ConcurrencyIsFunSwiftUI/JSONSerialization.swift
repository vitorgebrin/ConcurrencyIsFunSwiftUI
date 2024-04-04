//
//  JSONSerialization.swift
//  ConcurrencyIsFunSwiftUI
//
//  Created by Vitor Kalil on 01/04/24.
//

import SwiftUI

// This is just to document the way I was working with the JSON before turning to the Codable protocol for simplification purposes.

@MainActor class DEPRECATED:ObservableObject{
    @Published var plantCommonName:String = ""
    @Published var plantScientificName:String = ""
    @Published var plantFamily:String = ""
    @Published var plantSimilarImagesUrls:[String] = []
    let plantNetKey:String = ""
    
    
    func DEPRECATEDrequestRecognitionFormFormat(sentImage:UIImage) async throws{

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
