//
//  PushManager.swift
//  PushTestTool
//
//  Created by marco on 2022/7/22.
//

import Foundation
import SwiftUI
import APNSwift
import NIO
import JWTKit
import Dispatch

class PushManager: ObservableObject {
    
    enum ConnectState {
        case connecting, connected, disconnecting, disconnected
    }
    
    @Published var isConnected: Bool = false
    @Published var connectError: String?
    @Published var pushError: String?
    
    var connectState: ConnectState = .disconnected {
        didSet {
            DispatchQueue.main.async {
                self.isConnected = self.connectState == .connected
            }
        }
    }
    
    var apnsConnection: APNSwiftConnection?
    var eventGroup: MultiThreadedEventLoopGroup?
    
    func connectToApns(with filePath: String?, teamID: String, keyID: String, bundleID: String, isProduction: Bool) {
        guard connectState != .connecting, connectState != .disconnecting else {
            return
        }
        guard let filePath = filePath else {
            connectError = "Please Select a .p8 File"
            return
        }
        guard teamID.count > 0, keyID.count > 0, bundleID.count > 0 else {
            connectError = "TeamID/KeyID/BundleID missing!"
            return
        }
        
        connectError = nil
        connectState = .connecting
        
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let environment: APNSwiftConfiguration.Environment = isProduction ? .production : .sandbox
        
        DispatchQueue.global().async { [weak self] in
            guard let self = self else {
                return
            }
            do {
                let apnsConfig = try APNSwiftConfiguration(authenticationMethod:
                                                                .jwt(key: .private(filePath: filePath),
                                                                     keyIdentifier: JWKIdentifier(string: keyID),
                                                                     teamIdentifier: teamID),
                                                            topic: bundleID,
                                                            environment: environment)
                
                
                self.apnsConnection = try APNSwiftConnection.connect(configuration: apnsConfig, on: group.next()).wait()
                self.eventGroup = group
                self.connectState = .connected
            } catch {
                self.connectError = "Connect Failed!"
                self.connectState = .disconnected
                print(error)
            }
        }
        
    }
    
    func disconnect() {
        guard connectState != .connecting, connectState != .disconnecting else {
            return
        }
        guard let group = eventGroup, let apns = apnsConnection else {
            return
        }
        
        pushError = nil
        connectState = .disconnecting
        
        DispatchQueue.global().async { [weak self] in
            guard let self = self else {
                return
            }
            do {
                
                try apns.close().wait()
                try group.syncShutdownGracefully()
                self.connectState = .disconnected
                
            } catch {
                self.connectError = "Disconnect Failed!"
                print(error)
            }
        }
    }
    
    func pushMessage(with deviceToken: String, title: String, body: String, custom: String) {
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
            let aps = APNSwiftPayload(alert: .init(title: title, subtitle: "", body: body), badge: 1, hasContentAvailable: true)
            try apnsConnection.send(CustomNotification(aps: aps, custom: custom), pushType: .alert, to: deviceToken).wait()
        } catch {
            pushError = "\(error.localizedDescription)"
            print(error)
        }
        
    }
    
    
}
