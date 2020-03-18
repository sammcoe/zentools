//
//  ToolbarButtonStyle.swift
//  Zentools
//
//  Created by Samuel Coe on 3/13/20.
//  Copyright © 2020 Samuel Coe. All rights reserved.
//

import SwiftUI

struct ToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .frame(width: 50, height: 30)
            .background(configuration.isPressed ? Color.black.opacity(0.1) : .white)
            .cornerRadius(6.0)
            .padding(5)
    }
}
