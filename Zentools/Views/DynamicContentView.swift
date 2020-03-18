//
//  DynamicContentView.swift
//  Zentools
//
//  Created by Samuel Coe on 3/13/20.
//  Copyright © 2020 Samuel Coe. All rights reserved.
//

import SwiftUI

struct DynamicContentView: View {
    @State private var email: String = UserDefaults.standard.string(forKey: "Email") ?? ""
    @State private var sandboxApiKey: String = UserDefaults.standard.string(forKey: "SandboxApiKey") ?? ""
    @State private var productionApiKey: String = UserDefaults.standard.string(forKey: "ProdApiKey") ?? ""
    
    @State private var productionDynamicContent: [DynamicContent] = []
    @State private var isFetching: Bool = false
    
    var information: Binding<[String]>
    
    let prodHost: String = "https://classpass.zendesk.com"
    let sandboxHost: String = "https://classpass1510691354.zendesk.com"
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Ticket Fields")
                    .font(.title)
                
                Spacer()
                
                Button("Migrate Dynamic Content") {
                    self.migrateDynamicContent()
                }
            }

            if (productionDynamicContent.count > 0) {
                List(productionDynamicContent.map { $0 }, id: \.id) { dynamicContent in
                    VStack(alignment: .leading) {
                        Text("Dynamic Content")
                            .font(.headline)
                        
                        Button("Migrate Dynamic Content") {
                            self.migrateSingleDynamicContent(dynamicContent)
                        }
                        .id("\(dynamicContent.id)-migrate-button")
                        
                        ForEach(Mirror(reflecting: dynamicContent).children.map { "\($0.label ?? ""): \($0.value)" }, id: \.self) { value in
                            Text(value)
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
                
                VStack {
                    HStack {
                        if (isFetching) {
                            Spinner()
                        }
                    }
                }
                .frame(minWidth: 600, maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(5)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            self.getDynamicContent()
        }
    }
    
    func getDynamicContent() {
        isFetching.toggle()
        
        guard let url = URL(string: "\(prodHost)/api/v2/dynamic_content/items.json") else {
            print("Invalid URL")
            isFetching.toggle()
            return
        }
        guard let authString = "\(email)/token:\(productionApiKey)".data(using: .utf8)?.base64EncodedString() else {
            print("Could not encode auth string")
            isFetching.toggle()
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
                    let decodedResponse = try JSONDecoder().decode(DynamicContentResponse.self, from: data)
                    
                    DispatchQueue.main.async {
                        self.productionDynamicContent = decodedResponse.items
                    }
                    
                    self.information.wrappedValue.append("Got Dynamic Content!")
                    
                    self.isFetching.toggle()
                    return
                } catch {
                    print(error)
                }
            }
        }.resume()
    }
    
    func migrateDynamicContent() {
        let throttler = Throttler(minimumDelay: 1)
        
        productionDynamicContent.forEach { dynamicContent in
            throttler.throttle {
                self.migrateSingleDynamicContent(dynamicContent)
            }
        }
        self.information.wrappedValue.append("Migrate Dynamic Content complete!")
    }
    
    func migrateSingleDynamicContent(_ dynamicContent: DynamicContent) {
        information.wrappedValue.append("Migrating Dynamic Content: \(dynamicContent.id)")
        
        guard let authString = "\(email)/token:\(sandboxApiKey)".data(using: .utf8)?.base64EncodedString() else {
            self.information.wrappedValue.append("ERROR: Could not encode auth string")
            return
        }
        
        guard let url = URL(string: "\(sandboxHost)/api/v2/dynamic_content/items.json") else {
            self.information.wrappedValue.append("ERROR: Invalid URL")
            return
        }
        
        let requestBody = DynamicContentRequest(item: dynamicContent)
        guard let encodedData = try? JSONEncoder().encode(requestBody) else {
            self.information.wrappedValue.append("ERROR: Error encoding data")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(authString)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = encodedData
        
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                self.information.wrappedValue.append("ERROR: \(error.localizedDescription)")
                return
            }
            
            if let data = data {
                guard let response = String(bytes: data, encoding: .utf8) else { return }
                if response.contains("error") {
                    self.information.wrappedValue.append("ERROR: \(response)")
                } else {
                    self.information.wrappedValue.append("Successfully migrated Dynamic Content: \(dynamicContent.id)")
                }
                
                return
            }
        }.resume()
        
    }
}

struct DynamicContentView_Previews: PreviewProvider {
    static var previews: some View {
        DynamicContentView(information: .constant(["Test"]))
    }
}
