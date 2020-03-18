//
//  TicketForm.swift
//  Zentools
//
//  Created by Samuel Coe on 3/11/20.
//  Copyright © 2020 Samuel Coe. All rights reserved.
//

import Foundation

struct StatusRequirement: Codable {
    var type: String?
    var statuses: [String]?
}

struct ConditionChildField: Codable {
    var id: Int
    var is_required: Bool?
    var required_on_statuses: StatusRequirement?
}

struct Condition: Codable {
    var parent_field_id: Int?
    var value: String?
    var child_fields: [ConditionChildField]?
}

struct TicketForm: Codable {
    var id: Int
    var name: String?
    var raw_name: String?
    var display_name: String?
    var raw_display_name: String?
    var position: Int?
    var active: Bool?
    var end_user_visible: Bool?
    var ticket_field_ids: [Int]?
    var in_all_brands: Bool?
    var restricted_brand_ids: [Int]?
    var agent_conditions: [Condition]?
    var end_user_conditions: [Condition]?
}
