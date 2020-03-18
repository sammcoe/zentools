//
//  DynamicContent.swift
//  Zentools
//
//  Created by Samuel Coe on 3/13/20.
//  Copyright © 2020 Samuel Coe. All rights reserved.
//

import SwiftUI

struct DynamicContentVariant: Codable {
    var url: String
    var id: Int
    var content: String
    var locale_id: Int
    var outdated: Bool
    var active: Bool
    var `default`: Bool?
}

struct DynamicContent: Codable {
    var id: Int
    var url: String
    var name: String
    var placeholder: String
    var default_locale_id: Int
    var outdated: Bool
    var variants: [DynamicContentVariant]
    var `default`: Bool?
}
