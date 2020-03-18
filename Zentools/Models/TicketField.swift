//
//  TicketField.swift
//  Zentools
//
//  Created by Samuel Coe on 3/9/20.
//  Copyright © 2020 Samuel Coe. All rights reserved.
//

import Foundation

struct CustomFieldOption: Codable {
    var id: Int
    var name: String
    var raw_name: String
    var value: String
}

struct TicketField: Codable {
    var id: Int
    var url: String
    var type: String
    var title: String
    var raw_title: String
    var description: String
    var raw_description: String
    var position: Int
    var active: Bool
    var required: Bool
    var collapsed_for_agents: Bool
    var regexp_for_validation: String?
    var title_in_portal: String
    var raw_title_in_portal: String
    var visible_in_portal: Bool
    var editable_in_portal: Bool
    var required_in_portal: Bool
    var tag: String?
    var agent_description: String?
    var created_at: String
    var updated_at: String
    var custom_field_options: [CustomFieldOption]?
}
