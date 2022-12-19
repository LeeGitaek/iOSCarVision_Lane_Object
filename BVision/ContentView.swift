//
//  ContentView.swift
//  BVision
//
//  Created by gitaeklee on 12/5/22.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    var body: some View {
        HostedViewController()
            .ignoresSafeArea()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
