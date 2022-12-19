//
//  AccelerationView.swift
//  BVision
//
//  Created by gitaeklee on 12/6/22.
//

import SwiftUI
import CoreLocation
import MapKit

struct AccelerationView: View {
    
    @ObservedObject var accelerationViewModel = AccelerationViewModel()
    
    @State private var destination: String = "Where is your destination..?"
    
    var isStopSign: Bool = false
    var laneImage: UIImage?
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .center) {
                    Text("\(Int(accelerationViewModel.currentSpeed))")
                        .font(.system(size: 26.0))
                        .fontWeight(.regular)
                        .foregroundColor(.white)
                    Text(accelerationViewModel.unitString)
                        .foregroundColor(.white)
                        .fontWeight(.light)
                        .font(.system(size: 16.0))
                }
                .frame(width: 40, height: 40)
                .padding()
                .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white, lineWidth: 2)
                )
                
                Spacer()
                
                VStack(alignment: .center) {

                    Text("65")
                        .font(.system(size: 26.0))
                        .fontWeight(.regular)
                        .foregroundColor(.white)
                    
                    Text("MAX")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .font(.system(size: 16.0))
                }
                .frame(width: 40, height: 40)
                .padding()
                .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white, lineWidth: 2)
                )
            }
            .padding()
      
            HStack {
                VStack {
                    Button(action: {
                        print("route search in map")
                    }) {
                        Image("299087_marker_map_icon")
                            .frame(width: 40, height: 40)
                            .foregroundColor(Color.black)
                            .background(Color.white)
                            .opacity(0.7)
                            .clipShape(Circle())
                    }
                    .padding(EdgeInsets.init(top: 12, leading: 16, bottom: 12, trailing: 16))
                    
                    Button(action: {
                        print("link with my friend car")
                    }) {
                        Image("1988880_car_front_vehicle_icon")
                            .resizable()
                            .renderingMode(.original)
                            .frame(width: 40, height: 40)
                            .foregroundColor(Color.black)
                            .background(Color.white)
                            .opacity(0.7)
                            .clipShape(Circle())
                    }
                    .padding(EdgeInsets.init(top: 0, leading: 16, bottom: 12, trailing: 16))
                }
                
                Spacer()
                if isStopSign {
                    StopSign()
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text("STOP")
                                .font(.system(size: 20.0))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            , alignment: .center)
                        .padding()
                }
            }
            
            Spacer()
            
            HStack {
                
                Spacer()
                
                if laneImage != nil {
                    Image(uiImage: laneImage!)
                        .resizable()
                        .frame(width: 100, height: 100)
                        .padding()
                        .clipShape(Circle())
                }
            }
        }
        .navigationBarHidden(true)
    }
}
