//
//  Spinner.swift
//  Zentools
//
//  Created by Samuel Coe on 3/13/20.
//  Copyright © 2020 Samuel Coe. All rights reserved.
//

import SwiftUI

struct Spinner: View {
    @State var spinCircle = false

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.5, to: 1)
                .stroke(Color.blue, lineWidth:4)
                .frame(width: 50)
                .rotationEffect(.degrees(spinCircle ? 0 : -360), anchor: .center)
                .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: false))
        }
        .onAppear {
            self.spinCircle = true
        }
    }}

struct Spinner_Previews: PreviewProvider {
    static var previews: some View {
        Spinner()
    }
}
