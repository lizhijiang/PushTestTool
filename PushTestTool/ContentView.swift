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
    @State var teamID: String = ""
    @State var keyID: String = ""
    @State var bundelID: String = "" 
    @State var isConnected: Bool = false
    
    @State var deviceToken: String = ""
    
    @State var title: String = ""
    @State var content: String = ""
    @State var testUrl: String = ""
    
    @State var connectError: String?
    @State var pushError: String?
    
    //@State var apnsClient: APNSClient?
    @State var apnsConnection: APNSwiftConnection?
    @State var eventGroup: MultiThreadedEventLoopGroup?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button("Select .p8 File 📃 ") {
                filePath = chooseP8File()
            }
            Text(filePath ?? " Not choose any file")
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
                    Text("BundelID").font(.system(size: 12))
                    TextField("BundelID", text: $bundelID)
                }
            }
            HStack {
                Button(isConnected ? "Disconnect 🚧 " : "Connect 🛰 ") {
                    if isConnected {
                        disconnect()
                    } else {
                        connectToApns()
                    }
                }
                Toggle("Production", isOn: $isProduction).disabled(isConnected)
                Text(connectError ?? "").foregroundColor(.red)
            }
            Divider()
            if isConnected {
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
                            pushMessage()
                        }
                        Text(pushError ?? "").foregroundColor(.red)
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
    
    func connectToApns() {
        guard let filePath = filePath else {
            connectError = "Please Select a .p8 File"
            return
        }
        guard teamID.count > 0, keyID.count > 0, bundelID.count > 0 else {
            connectError = "TeamID/KeyID/BundelID missing!"
            return
        }
        connectError = nil
        
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let environment: APNSwiftConfiguration.Environment = isProduction ? .production : .sandbox
        do {
            let apnsConfig = try APNSwiftConfiguration(authenticationMethod:
                                                            .jwt(key: .private(filePath: filePath),
                                                                 keyIdentifier: JWKIdentifier(string: keyID),
                                                                 teamIdentifier: teamID),
                                                        topic: bundelID,
                                                        environment: environment)
            
            apnsConnection = try APNSwiftConnection.connect(configuration: apnsConfig, on: group.next()).wait()
            eventGroup = group
            
            isConnected = true
            
        } catch {
            connectError = "Connect Failed!"
            print(error)
        }
        
    }
    
    func disconnect() {
        if let group = eventGroup, let apns = apnsConnection {
            do {
                try apns.close().wait()
                try group.syncShutdownGracefully()
                
                isConnected = false
                
            } catch {
                connectError = "Disconnect Failed!"
                print(error)
            }
        }
    }
    
    func pushMessage() {
        guard let apnsConnection = apnsConnection else {
            return
        }
        guard deviceToken.count > 0 else {
            pushError = "DeviceToken missing!"
            return
        }
        guard title.count > 0 else {
            pushError = "Title missing!"
            return
        }
        
        pushError = nil

        do {
            let aps = APNSwiftPayload(alert: .init(title: title, subtitle: "", body: content), badge: 1, hasContentAvailable: true)
            try apnsConnection.send(CustomNotification(aps: aps, custom: testUrl), pushType: .alert, to: deviceToken).wait()
        } catch {
            pushError = "\(error.localizedDescription)"
            print(error)
        }
        
    }
    
    /*
    func connect() -> APNSClient? {
        guard let filePath = filePath else {
            errorMsg = "请选择证书文件"
            return nil
        }
        guard teamID.count > 0, keyID.count > 0, bundelID.count > 0 else {
            errorMsg = "请填写teamID/KeyID/bundelID"
            return nil
        }
        errorMsg = nil
        
        
        do {
            let authenticationConfig: APNSConfiguration.Authentication = .init(
                privateKey: try .loadFrom(filePath: filePath),
                teamIdentifier: teamID,
                keyIdentifier: keyID
            )
            
            let apnsConfig = APNSConfiguration(
                authenticationConfig: authenticationConfig,
                topic: bundelID,
                environment: isProduction ? .production : .sandbox,
                eventLoopGroupProvider: .createNew
            )
            
            isConnected = true
            
            return APNSClient(configuration: apnsConfig)
            
        } catch {
            isConnected = false
            errorMsg = "连接失败"
            print("Unexpected error: \(error).")
        }
        
        return nil
    }
     
    
    func disconnect() {
        guard let apnsClient = apnsClient else {
            return
        }
        Task {
            do {
                try await apnsClient.shutdown()
                self.apnsClient = nil
                isConnected = false
            } catch {
                errorMsg = "断开连接失败"
            }
        }
    }
     */
    
    /*
    func pushMessage() {
        guard let apnsClient = apnsClient else {
            return
        }
        guard deviceToken.count > 0 else {
            return
        }
        
        let aps = APNSPayload(alert: .init(title: title, subtitle: subtitle, body: ""), hasContentAvailable: true)
        let notification = TTNotification(aps: aps)
        Task {
            try await apnsClient.send(notification, pushType: .alert, to: deviceToken)
        }
        
    }
    */
    

    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
