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
            ContentView().tabItem { Image(systemName: "leaf.fill") }.tag(0)
            Text("Second View").tabItem { Image(systemName: "clock") }.tag(1)
            Text("Third View").tabItem { Image(systemName: "doc.questionmark") }.tag(2)
        }
    }
}

#Preview {
    GeneralView()
}
