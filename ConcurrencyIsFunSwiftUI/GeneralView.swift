//
//  GeneralView.swift
//  ConcurrencyIsFunSwiftUI
//
//  Created by Vitor Kalil on 30/03/24.
//

import SwiftUI

struct GeneralView: View {
    var body: some View {
        TabView{
            ContentView().tabItem { Image(systemName: "camera") }.tag(0)
            Text("Second View").tabItem { Image(systemName: "person") }.tag(1)
            Text("Third View").tabItem { Image(systemName: "lightbulb") }.tag(2)
        }
    }
}

#Preview {
    GeneralView()
}
