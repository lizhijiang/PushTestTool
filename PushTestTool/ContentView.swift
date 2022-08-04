//
//  ContentView.swift
//  ApnsTool
//
//  Created by marco on 2022/7/20.
//

import SwiftUI
import APNSwift
import NIO
import JWTKit


struct CustomNotification: APNSwiftNotification {
    let aps: APNSwiftPayload
    var customKey: String
    
    init(aps: APNSwiftPayload, custom: String) {
        self.aps = aps
        self.customKey = custom
    }
}

struct ContentView: View {
    @State var isProduction: Bool = false
    @State var filePath: String?
    @State var teamID: String = UserDefaults.standard.string(forKey: "teamID") ?? ""
    @State var keyID: String = UserDefaults.standard.string(forKey: "keyID") ?? ""
    @State var bundleID: String = UserDefaults.standard.string(forKey: "bundleID") ?? ""
    
    @State var deviceToken: String = ""
    
    @State var title: String = ""
    @State var content: String = ""
    @State var testUrl: String = ""
    
    @StateObject var pushManager = PushManager()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button("Select a .p8 File 📃 ") {
                filePath = chooseP8File()
            }
            Text(filePath ?? " Not selecting any file")
            Divider()
            HStack {
                VStack(alignment: .leading) {
                    Text("TeamID").font(.system(size: 12))
                    TextField("TeamID", text: $teamID)
                }
                Spacer(minLength: 20)
                VStack(alignment: .leading) {
                    Text("KeyID").font(.system(size: 12))
                    TextField("KeyID", text: $keyID)
                }
                Spacer(minLength: 20)
                VStack(alignment: .leading) {
                    Text("BundleID").font(.system(size: 12))
                    TextField("BundleID", text: $bundleID)
                }
            }
            HStack {
                Button(pushManager.isConnected ? "Disconnect 🚧 " : "Connect 🛰 ") {
                    if pushManager.isConnected {
                        pushManager.disconnect()
                    } else {
                        pushManager.connectToApns(with: filePath, teamID: teamID, keyID: keyID, bundleID: bundleID, isProduction: isProduction)
                        UserDefaults.standard.set(teamID, forKey: "teamID")
                        UserDefaults.standard.set(keyID, forKey: "keyID")
                        UserDefaults.standard.set(bundleID, forKey: "bundleID")
                    }
                }
                Toggle("Production", isOn: $isProduction).disabled(pushManager.isConnected)
                Text(pushManager.connectError ?? "").foregroundColor(.red)
            }
            Divider()
            if pushManager.isConnected {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("DeviceToken").font(.system(size: 12))
                        TextField("DeviceToken", text: $deviceToken)
                    }
                    VStack(alignment: .leading) {
                        Text("Title And Body").font(.system(size: 12))
                        HStack {
                            TextField("Title", text: $title)
                            TextField("Body", text: $content)
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("Your custom data").font(.system(size: 12))
                        TextField("Rename or add some other key", text: $testUrl)
                    }
                    
                    HStack {
                        Button("Push Message 🚀 ") {
                            pushManager.pushMessage(with: deviceToken, title: title, body: content, custom: testUrl)
                        }
                        Text(pushManager.pushError ?? "").foregroundColor(.red)
                    }
                }
            }
        }.padding(20)
        .frame(minWidth: 450, idealWidth: 450, maxWidth: 450, minHeight: 500, idealHeight: 500, maxHeight: 500, alignment: .top)
    }
    
    func chooseP8File() -> String? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            return panel.url?.path
        } else {
            return nil
        }
    }

    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
