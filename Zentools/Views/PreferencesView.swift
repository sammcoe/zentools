//
//  PreferencesView.swift
//  Zentools
//
//  Created by Samuel Coe on 3/13/20.
//  Copyright © 2020 Samuel Coe. All rights reserved.
//

import SwiftUI

struct PreferencesView: View {
    @State private var email: String = UserDefaults.standard.string(forKey: "Email") ?? ""
    @State private var sandboxApiKey: String = UserDefaults.standard.string(forKey: "SandboxApiKey") ?? ""
    @State private var productionApiKey: String = UserDefaults.standard.string(forKey: "ProdApiKey") ?? ""
    @State private var themeDirectory: String = UserDefaults.standard.string(forKey: "ThemeDirectory") ?? ""
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Form {
            Section(header: Text("Zendesk Account Email")) {
                TextField("Account Email", text: $email)
            }
            
            Section(header: Text("Sandbox API Key")) {
                TextField("Sandbox API Key", text: $sandboxApiKey)
            }
            
            Section(header: Text("Production API Key")) {
                TextField("Production API Key", text: $productionApiKey)
            }
            
            Section(header: Text("Zendesk Guides Theme Directory")) {
                VStack(alignment: .leading) {
                    if self.themeDirectory != "" {
                        TextField("", text: .constant("\(themeDirectory)"))
                    } else {
                        TextField("", text: .constant("No selection"))
                    }
                    Button(action: {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            let result = panel.runModal()
                            if result == .OK {
                                self.themeDirectory = panel.url?.absoluteString ?? ""
                            }
                        }
                    }) {
                        Text("Select directory")
                    }
                }
            }

            HStack {
                Button("Cancel", action: {
                    self.presentationMode.wrappedValue.dismiss()
                })
                
                Spacer()
                
                Button("Save", action: setPreferences)
            }
            .padding([.top], 20)
        }
        .padding()
        .frame(width: 400, height: 300)
    }
    
    func setPreferences() {
        UserDefaults.standard.set(self.email, forKey: "Email")
        UserDefaults.standard.set(self.productionApiKey, forKey: "ProdApiKey")
        UserDefaults.standard.set(self.sandboxApiKey, forKey: "SandboxApiKey")
        UserDefaults.standard.set(self.themeDirectory, forKey: "ThemeDirectory")
        
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
