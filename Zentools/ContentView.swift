//
//  ContentView.swift
//  Zentools
//
//  Created by Samuel Coe on 3/9/20.
//  Copyright © 2020 Samuel Coe. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State private var email: String = UserDefaults.standard.string(forKey: "Email") ?? ""
    @State private var sandboxApiKey: String = UserDefaults.standard.string(forKey: "SandboxApiKey") ?? ""
    @State private var productionApiKey: String = UserDefaults.standard.string(forKey: "ProdApiKey") ?? ""
    @State private var themeDirectory: String = UserDefaults.standard.string(forKey: "ThemeDirectory") ?? ""
    
    @State private var productionTicketFields: [TicketField] = []
    @State private var sandboxTicketFields: [TicketField] = []
    @State private var productionTicketForms: [TicketForm] = []
    
    @State private var information: [String] = ["Log Start"]
    @State private var mostRecentlyCreatedTicket: TicketField?
    @State private var ticketFieldMapping: [Int : Int] = [:]
    @State private var isFetching = true
    @State private var isShowingPreferences: Bool = false
    
    
    private var ticketFieldStrings: [[String]] {
        Mirror(reflecting: productionTicketFields).children.map { field in
            let fieldValues = Mirror(reflecting: field.value).children.map { fieldValues in
                "\(fieldValues.label ?? ""): \(fieldValues.value)"
            }
            return fieldValues
        }
    }
    
    let prodHost: String = "https://classpass.zendesk.com"
    let sandboxHost: String = "https://classpass1510691354.zendesk.com"

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    self.isShowingPreferences.toggle()
                }) {
                    Image("gear")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(ToolbarButtonStyle())

                Spacer()
            }
            .background(Color.black.opacity(0.1))
            
            TabView {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Ticket Fields")
                            .font(.title)
                        
                        Spacer()
                        
                        Button("Sync fields to Theme") {
                            self.updateFieldsInLocalThemeFiles()
                        }
                        .disabled(self.sandboxTicketFields.count == 0 || self.productionTicketFields.count == 0)
                        
                        Button("Migrate Ticket Fields") {
                            self.migrateTicketFields()
                        }
                        .disabled(self.productionTicketFields.count == 0)
                        
                        Button("Delete Sandbox Fields") {
                            self.deleteSandboxTicketFields()
                        }
                        .disabled(self.productionTicketForms.count == 0)
                    }

                    if (productionTicketFields.count > 0) {
                        List(productionTicketFields.map { $0 }, id: \.id) { ticketField in
                            VStack(alignment: .leading) {
                                Text("Field")
                                    .font(.headline)
                                
                                Button("Migrate Field") {
                                    self.migrateSingleTicketField(ticketField)
                                }
                                .id("\(ticketField.id)-migrate-button")
                                
                                ForEach(Mirror(reflecting: ticketField).children.map { "\($0.label ?? ""): \($0.value)" }, id: \.self) { fieldValue in
                                    Text(fieldValue)
                                }
                                .padding([.leading], 15)
                            }
                            .padding([.bottom], 10)
                        }
                        .frame(minWidth: 600)
                        .background(Color.white)
                        .cornerRadius(5)
                    } else {
                        Spacer()
                        
                        HStack {
                            if (isFetching) {
                                Spinner()
                            }
                        }
                        .frame(minWidth: 600, maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(5)
                    }
                    
                    Spacer()
                }
                .padding()
                .tabItem {
                    Text("Ticket Fields")
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Ticket Forms")
                            .font(.title)
                        
                        Spacer()
                        
                        Button("Migrate Ticket Forms") {
                            self.migrateTicketForms()
                        }
                        .disabled(self.productionTicketForms.count == 0)
                    }

                    if (productionTicketForms.count > 0) {
                        List(productionTicketForms.map { $0 }, id: \.id) { ticketForm in
                            VStack(alignment: .leading) {
                                Text("Form")
                                    .font(.headline)
                                
                                Button("Migrate Form") {
                                    self.migrateSingleTicketForm(ticketForm)
                                }
                                .id("\(ticketForm.id)-migrate-button")
                                
                                ForEach(Mirror(reflecting: ticketForm).children.map { "\($0.label ?? ""): \($0.value)" }, id: \.self) { fieldValue in
                                    Text(fieldValue)
                                }
                                .padding([.leading], 15)
                            }
                            .padding([.bottom], 10)
                        }
                        .frame(minWidth: 600)
                        .background(Color.white)
                    } else {
                        Spacer()
                        
                        HStack {
                            if (isFetching) {
                                Spinner()
                            }
                        }
                        .frame(minWidth: 600, maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(5)
                    }
                    
                    Spacer()
                }
                .padding()
                .tabItem {
                    Text("Ticket Forms")
                }
                
                DynamicContentView(information: $information)
                    .tabItem {
                        Text("Dynamic Content")
                    }
            }
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .sheet(isPresented: $isShowingPreferences) {
                PreferencesView()
            }
            

            VStack {
                List(information.reversed(), id: \.self) { item in
                    Text(item)
                }
                Spacer()
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 200)
            .background(Color.white)
            .cornerRadius(5)
            .padding()
            .onAppear {
                self.getTicketForms()
                self.getTicketFields(env: "prod", onComplete: nil)
                self.getTicketFields(env: "sandbox", onComplete: nil)
            }
        }
    }

    func getMatchingSandboxFieldId(_ productionId: Int) -> Int {
        if let match = ticketFieldMapping[productionId] {
            return match
        }
        
        let productionField = self.productionTicketFields.first(where: { field in
            field.id == productionId
        })
        
        let sandboxField = self.sandboxTicketFields.first(where: { field in
            field.title == productionField?.title
        })
        
        return sandboxField?.id ?? 0
    }
    
    func getSandboxConditionValues(_ conditions: [Condition]) -> [Condition] {
        conditions.map { condition -> Condition in
            var parentFieldSandboxId: Int? = condition.parent_field_id
            if let parentFieldId = condition.parent_field_id {
                parentFieldSandboxId = self.getMatchingSandboxFieldId(parentFieldId)
            }
            
            var sandboxChildFields: [ConditionChildField]? = condition.child_fields
            if let childFields = condition.child_fields {
                sandboxChildFields = childFields.map { childField in
                    let sandboxId = self.getMatchingSandboxFieldId(childField.id)
                    return ConditionChildField(id: sandboxId, is_required: childField.is_required, required_on_statuses: childField.required_on_statuses)
                }
            }
            
            return Condition(parent_field_id: parentFieldSandboxId, value: condition.value, child_fields: sandboxChildFields)
        }
    }
    
    func updateFieldsInLocalThemeFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let result = panel.runModal()
            if result == .OK {
                if let url = panel.url {
                    do {
                        let scriptPath = url.appendingPathComponent("script.js")
                        var scriptString = try String(contentsOfFile: scriptPath.path)
                        if (self.productionTicketFields.count > 0) {
                            self.productionTicketFields.forEach { productionField in
                                let sandboxId = self.getMatchingSandboxFieldId(productionField.id)
                                self.information.append("Replacing \(productionField.id) with \(sandboxId) in script.js")
                                scriptString = scriptString.replacingOccurrences(of: "\(productionField.id)", with: "\(sandboxId)")
                            }
                            print(scriptString)
                        }
                        
                        try scriptString.write(to: scriptPath, atomically: true, encoding: .utf8)

                        let requestPagePath = url.appendingPathComponent("templates/new_request_page.hbs")
                        var requestPageString = try String(contentsOfFile: requestPagePath.path)
                        if (self.productionTicketFields.count > 0) {
                            self.productionTicketFields.forEach { productionField in
                                let sandboxId = self.getMatchingSandboxFieldId(productionField.id)
                                self.information.append("Replacing \(productionField.id) with \(sandboxId) in new_request_page.hbs")
                                requestPageString = requestPageString.replacingOccurrences(of: "\(productionField.id)", with: "\(sandboxId)")
                            }
                        }
                        
                        try requestPageString.write(to: requestPagePath, atomically: true, encoding: .utf8)
                    } catch {
                        print(error)
                        self.information.append("ERROR: \(error)")
                    }
                }
            }
        }
    }
    
    func getTicketFields(env: String, onComplete: (([TicketField]) -> ())?) {
        guard let url = URL(string: "\(env == "prod" ? prodHost : sandboxHost)/api/v2/ticket_fields.json") else {
            print("Invalid URL")
            self.isFetching.toggle()
            return
        }
        guard let authString = "\(email)/token:\(env == "prod" ? productionApiKey : sandboxApiKey)".data(using: .utf8)?.base64EncodedString() else {
            print("Could not encode auth string")
            self.isFetching.toggle()
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Basic \(authString)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print(error)
                self.isFetching.toggle()
                return
            }
            if let data = data {
//                print(String(data: data, encoding: .utf8))
                do {
                    let decodedResponse = try JSONDecoder().decode(TicketFieldsResponse.self, from: data)
                    
                    DispatchQueue.main.async {
                        if (env == "prod") {
                            self.productionTicketFields = decodedResponse.ticket_fields
                        } else {
                            self.sandboxTicketFields = decodedResponse.ticket_fields
                        }
                        
                        self.information.append("Got ticket fields!")
                        
                        if let onComplete = onComplete {
                            onComplete(decodedResponse.ticket_fields)
                        }
                    }
                    
                    self.isFetching.toggle()
                    return
                } catch {
                    print(error)
                }
            }
        }.resume()
    }
        
    func getTicketForms() {
        guard let url = URL(string: "\(prodHost)/api/v2/ticket_forms.json") else {
            print("Invalid URL")
            self.isFetching.toggle()
            return
        }
        guard let authString = "\(email)/token:\(productionApiKey)".data(using: .utf8)?.base64EncodedString() else {
            print("Could not encode auth string")
            self.isFetching.toggle()
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Basic \(authString)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print(error)
            self.isFetching.toggle()
                return
            }
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(TicketFormsResponse.self, from: data)
                    
                    DispatchQueue.main.async {
                        self.productionTicketForms = decodedResponse.ticket_forms
                    }
                    
                    self.information.append("Got ticket forms!")
                    
                    self.isFetching.toggle()
                    return
                } catch {
                    print(error)
                }
            }
        }.resume()
    }
    
    func migrateTicketForms() {
        productionTicketForms.forEach { form in
            migrateSingleTicketForm(form)
        }
        self.information.append("Migrate ticket forms complete!")
    }
    
    func migrateSingleTicketForm(_ form: TicketForm) {
        information.append("Migrating Ticket Form: \(form.id)")
        
        guard let authString = "\(email)/token:\(sandboxApiKey)".data(using: .utf8)?.base64EncodedString() else {
            self.information.append("ERROR: Could not encode auth string")
            return
        }
        
        guard let url = URL(string: "\(sandboxHost)/api/v2/ticket_forms.json") else {
            self.information.append("ERROR: Invalid URL")
            return
        }
    
        // Transform field array
        guard let ticketFieldIds = form.ticket_field_ids else {
            print("No ticket fields")
            return
        }
        let transformedFieldArray: [Int] = ticketFieldIds.map { fieldId in
            self.getMatchingSandboxFieldId(fieldId)
        }
        
        var transformedEndUserConditions: [Condition]? = form.end_user_conditions
        if let endUserConditions: [Condition] = form.end_user_conditions {
            transformedEndUserConditions = getSandboxConditionValues(endUserConditions)
        }
        
        var transformedAgentConditions: [Condition]? = form.agent_conditions
        if let agentConditions: [Condition] = form.agent_conditions {
            transformedAgentConditions = getSandboxConditionValues(agentConditions)
        }
        
        let transformedForm = TicketForm(id: form.id, name: form.name, raw_name: form.raw_name, display_name: form.display_name, raw_display_name: form.raw_display_name, position: form.position, active: form.active, end_user_visible: form.end_user_visible, ticket_field_ids: transformedFieldArray, in_all_brands: form.in_all_brands, restricted_brand_ids: form.restricted_brand_ids, agent_conditions: transformedAgentConditions, end_user_conditions: transformedEndUserConditions)
        
        let requestBody = TicketFormRequest(ticket_form: transformedForm)
        guard let encodedData = try? JSONEncoder().encode(requestBody) else {
            self.information.append("ERROR: Error encoding data")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(authString)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = encodedData
        
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                self.information.append("ERROR: \(error.localizedDescription)")
                return
            }
            
            if let data = data {
                guard let response = String(bytes: data, encoding: .utf8) else { return }
                if response.contains("error") {
                    self.information.append("ERROR: \(response)")
                } else {
                    self.information.append("Successfully migrated Ticket Form: \(form.id)")
                }
                
                return
            }
        }.resume()
    }
    
    func migrateTicketFields() {
        let throttler = Throttler(minimumDelay: 1)
        
        productionTicketFields.forEach { field in
            throttler.throttle {
                self.migrateSingleTicketField(field)
            }
        }
        getTicketFields(env: "sandbox", onComplete: nil)
        self.information.append("Migrate ticket forms complete!")
    }
    
    func deleteSandboxTicketFields() {
        getTicketFields(env: "sandbox", onComplete: { fields in
            fields.forEach { field in
                self.information.append("Deleting Ticket Field: \(field.id)")
                
                guard let authString = "\(self.email)/token:\(self.sandboxApiKey)".data(using: .utf8)?.base64EncodedString() else {
                    self.information.append("Could not encode auth string")
                    return
                }
                
                guard let url = URL(string: "\(self.sandboxHost)/api/v2/ticket_fields/\(field.id).json") else {
                    self.information.append("Invalid URL")
                    return
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "DELETE"
                request.setValue("Basic \(authString)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        self.information.append("\(error.localizedDescription)")
                        return
                    }
                    
                    if let data = data {
                        guard let response = String(bytes: data, encoding: .utf8) else { return }
                        if response.contains("error") {
                            self.information.append("ERROR: \(response)")
                        } else {
                            self.information.append("Successfully deleted Ticket Field: \(field.id)")
                        }
                        
                        return
                    }
                }.resume()
            }
        })
    }
    
    func migrateSingleTicketField(_ field: TicketField) {
        information.append("Migrating Ticket Field: \(field.id)")
        
        guard let authString = "\(email)/token:\(sandboxApiKey)".data(using: .utf8)?.base64EncodedString() else {
            self.information.append("Could not encode auth string")
            return
        }
        
        guard let url = URL(string: "\(sandboxHost)/api/v2/ticket_fields.json") else {
            self.information.append("Invalid URL")
            return
        }
        
        let requestBody = TicketFieldRequest(ticket_field: field)
        guard let encodedData = try? JSONEncoder().encode(requestBody) else {
            self.information.append("Error encoding data")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(authString)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = encodedData
        
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                self.information.append("ERROR: \(error.localizedDescription)")
                return
            }
            
            if let data = data {
                do {
                    guard let response = String(bytes: data, encoding: .utf8) else { return }
                    if response.contains("error") {
                        self.information.append("ERROR: \(response)")
                        return
                    }
                    
                    let decodedResponse = try JSONDecoder().decode(TicketFieldResponse.self, from: data)
                    
                    self.ticketFieldMapping[field.id] = decodedResponse.ticket_field.id
                    
                    self.mostRecentlyCreatedTicket = decodedResponse.ticket_field
                    
                    self.information.append("Successfully migrated Ticket Field: \(field.id)")
                    
                    return
                } catch {
                    self.information.append("ERROR: \(error.localizedDescription)")
                    print(error)
                }
            }
        }.resume()
    }
    
    func migrateTicketFieldOptions(_ options: [CustomFieldOption], fieldId: Int) {
        guard let authString = "\(email)/token:\(sandboxApiKey)".data(using: .utf8)?.base64EncodedString() else {
            self.information.append("Could not encode auth string")
            return
        }
        
        guard let url = URL(string: "\(sandboxHost)/api/v2/ticket_fields/\(fieldId)/options.json") else {
            self.information.append("ERROR: Invalid URL")
            return
        }
        
        options.forEach { option in
            information.append("Migrating Ticket Field: \(option.id)")
            
            let requestBody = TicketFieldOptionRequest(custom_field_option: option)
            guard let encodedData = try? JSONEncoder().encode(requestBody) else {
                self.information.append("ERROR: Error encoding data")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Basic \(authString)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = encodedData
            
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    self.information.append("ERROR: \(error.localizedDescription)")
                    return
                }
                
                if let data = data {
                    guard let response = String(bytes: data, encoding: .utf8) else { return }
                    if response.contains("error") {
                        self.information.append("ERROR: \(response)")
                    } else {
                        self.information.append("Successfully migrated Ticket Field Option: \(option.id)")
                    }
                    
                    return
                }
            }.resume()
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
