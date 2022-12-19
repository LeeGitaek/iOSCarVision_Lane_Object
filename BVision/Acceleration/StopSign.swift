//
//  StopSign.swift
//  BVision
//
//  Created by gitaeklee on 12/13/22.
//

import SwiftUI

struct StopSign: View {
    var body: some View {
        Path { path in
            var width: CGFloat = 80
            let height = width
            let xScale: CGFloat = 0.832
            let xOffset = (width * (1.0 - xScale)) / 2.0
            width *= xScale
            path.move(
                to: CGPoint(
                    x: width * 0.95 + xOffset,
                    y: height * (0.20 + HexagonParameters.adjustment)
                )
            )
            
            HexagonParameters.segments.forEach { segment in
                path.addLine(
                    to: CGPoint(
                        x: width * segment.line.x + xOffset,
                        y: height * segment.line.y
                    )
                )
                
                path.addQuadCurve(
                    to: CGPoint(
                        x: width * segment.curve.x + xOffset,
                        y: height * segment.curve.y
                    ),
                    control: CGPoint(
                        x: width * segment.control.x + xOffset,
                        y: height * segment.control.y
                    )
                )
            }
        }
        .fill(.linearGradient(
            Gradient(colors: [Self.gradientStart, Self.gradientEnd]),
            startPoint: UnitPoint(x: 0.5, y: 0),
            endPoint: UnitPoint(x: 0.5, y: 0.6)
        ))
    }
    static let gradientStart = Color(red: 1.0, green: 0.0, blue: 0.0)
    static let gradientEnd = Color(red: 1.0, green: 0.0, blue: 0.0)
}

struct StopSign_Previews: PreviewProvider {
    static var previews: some View {
        StopSign()
    }
}
