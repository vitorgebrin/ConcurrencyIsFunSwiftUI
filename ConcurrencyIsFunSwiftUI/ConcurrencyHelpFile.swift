
//  Created by Vitor Kalil on 25/03/24.
// This file's main purpose is to help me remind myself of the different ways I have to code with asynchronous code. In general, I should use the Async/Await method but it is fundamental to know the other functions

//This code is based on the video of Async/Await, @escaping and Combine on https://youtu.be/9fXI6o39jLQ?si=dKVtaiOiDqiFtwAo

import SwiftUI
import Combine


class DownloadImageAsyncImageLoader {
    let url = URL(string: "https://picsum.photos/250")!
    
    // This function is to handle the response for every method used
    func handleResponse(data:Data?, response:URLResponse?) -> UIImage? {
        guard
            let data = data,
            let image = UIImage(data: data),
            let response = response as? HTTPURLResponse,
            response.statusCode >= 200 && response.statusCode < 300 else{ // general HTTP response codes
            return nil}
        return image
    }
    
    // This is the function to get image asynchronously using Escaping, a very old way to use asynchronous code in Swift
    func downloadWithEscaping(completionHandler: @escaping (_ image:UIImage?, _ error:Error?) -> ()){
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            let image = self?.handleResponse(data: data, response: response)
            completionHandler(image,error)
        }.resume()
    }
    
    // This is the function to get image asynchronously using Combine framework
    func downloadWithCombine() -> AnyPublisher<UIImage?,Error> {
        URLSession.shared.dataTaskPublisher(for: url)
            .map(handleResponse) // I can use the function without passing the parameters because swift assume the parameters since they have the same name
            .mapError({ $0 }) // map the URLError to a regular error
            .eraseToAnyPublisher()
    }
    
    // This is the function to get image asynchronously using Async/Await, the newest way to do it in Swift
    func downloadWithAsync() async throws -> UIImage?{ // Async functions need to be marked with the async keyword
        do {
            let (data,response) = try await URLSession.shared.data(from: url) 
            // since this is a asynchronous function, I need to wait for the result. To do that, we use the keyword await
            let image = handleResponse(data: data, response: response)
            return image
        } catch  {
            throw error
        }
        
        
    }
}

class DownloadImageAsyncViewModel: ObservableObject{
    @Published var image:UIImage? = nil
    let loader = DownloadImageAsyncImageLoader()
    var cancellables = Set<AnyCancellable>() // used only on combine
    func fetchImage() async { // this keyword async is needed just to the method with Async/await (read above)
        
        /*
         loader.downloadWithEscaping {[weak self] image, error in
            DispatchQueue.main.async { // This is needed to go back to the main thread
            self?.image = image
            }
        }
        loader.downloadWithCombine()
            .receive(on:DispatchQueue.main)// This is needed to go back to the main thread
            .sink {_ in
                
            } receiveValue: { [weak self] image in
                    self?.image = image
            }.store(in: &cancellables)*/
        
        let image = try? await loader.downloadWithAsync()
       await MainActor.run{ // This is needed to go back to the main thread
            self.image = image
        }
    }
}
struct DownloadImageAsync: View {
    @StateObject private var viewModel = DownloadImageAsyncViewModel()
    var body: some View {
        ZStack{
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width:250,height:250)
            }
        }.onAppear{
            Task { // In a very simple way, we use the Task to enter the Asynchronous code
                await viewModel.fetchImage()
            }
        }
    }
}

#Preview {
    DownloadImageAsync()
}



