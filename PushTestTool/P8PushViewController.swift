//
//  P8PushViewController.swift
//  PushTestTool
//
//  Created by Marco on 2020/11/3.
//

import Cocoa
import APNSwift
import NIO
import JWTKit

class P8PushViewController: NSViewController, NSMenuDelegate {

    @IBOutlet weak var certSelectPopUpButton: NSPopUpButton!
    @IBOutlet weak var envSelectPopUpButton: NSPopUpButton!
    @IBOutlet weak var keyIdTextField: NSTextField!
    @IBOutlet weak var teamIdTextField: NSTextField!
    @IBOutlet weak var deviceTokenTextField: NSTextField!
    @IBOutlet weak var bundelIdTextField: NSTextField!
    
    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var subtitleTextField: NSTextField!
    @IBOutlet weak var bodyTextField: NSTextField!
    @IBOutlet weak var appDataTextField: NSTextField!
    
    @IBOutlet weak var connectButton: NSButton!
    @IBOutlet weak var pushButton: NSButton!
    @IBOutlet weak var errorLabel: NSTextField!
    
    var openPanel: NSOpenPanel?
    var certFilePath: String?
    var keyId: String?
    var teamId: String?
    var deviceToken: String?
    var bundelId: String?
    
    var pushTitle: String?
    var pushSubtitle: String?
    var pushBody: String?
    
    var apnsConnection: APNSwiftConnection?
    var eventGroup: MultiThreadedEventLoopGroup?
    
    var lastEnv: APNSwiftConfiguration.Environment?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.envSelectPopUpButton.menu?.delegate = self
        self.connectButton.action = #selector(connectAction)
        
    }
    
    override func viewDidAppear() {
        
    }
    
    override func viewDidDisappear() {
        
        self.errorLabel.stringValue = ""
        disconnectAction()
        
    }
    
    //MARK: NSMenuDelegate
    func menuWillOpen(_ menu: NSMenu) {
        self.lastEnv = self.envSelectPopUpButton.selectedTag() == 0 ? .sandbox : .production
    }
    
    func menuDidClose(_ menu: NSMenu) {
        let currentEnv: APNSwiftConfiguration.Environment = self.envSelectPopUpButton.selectedTag() == 0 ? .sandbox : .production
        if self.lastEnv == currentEnv {
            return
        }
        disconnectAction()
    }
    
    //MARK: Actions
    @IBAction func certSelectAction(_ sender: Any) {
        self.openPanel = NSOpenPanel()
        self.openPanel?.canChooseFiles = true
        self.openPanel?.canChooseDirectories = true
        self.openPanel?.allowedFileTypes = ["p8"]
        self.openPanel?.begin { [weak self] result in
            if result.rawValue == 1 {
                if let path = self?.openPanel?.urls.first?.path {
                    self?.certFilePath = path
                    self?.certSelectPopUpButton.selectedItem?.title = path
                }
            }
        }
        
    }
    
    @objc
    func connectAction() {
        
        self.keyId = self.keyIdTextField.stringValue
        self.teamId = self.teamIdTextField.stringValue
        
        guard let certPath = self.certFilePath, let keyId = self.keyId, let teamId = self.teamId else {
            return
        }
        
        self.bundelId = self.bundelIdTextField.stringValue
        
        guard let bundelId = self.bundelId else {
            return
        }
        
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        let environment: APNSwiftConfiguration.Environment = self.envSelectPopUpButton.selectedTag() == 1 ? .production : .sandbox
        do {
            let apnsConfig = try APNSwiftConfiguration(authenticationMethod:
                                                            .jwt(key: .private(filePath: certPath),
                                                                 keyIdentifier: JWKIdentifier(string: keyId),
                                                                 teamIdentifier: teamId),
                                                        topic: bundelId,
                                                        environment: environment)
            
            self.apnsConnection = try APNSwiftConnection.connect(configuration: apnsConfig, on: group.next()).wait()
            self.eventGroup = group
            
            self.switchConnectButton(isConnected: true)
            self.pushButton.isEnabled = true
            self.errorLabel.stringValue = ""
            
        } catch {
            self.pushButton.isEnabled = false
            self.errorLabel.stringValue = "\(error)"
            print(error)
        }
        
    }
    
    @objc
    func disconnectAction() {
        if let group = self.eventGroup, let apns = self.apnsConnection {
            do {
                try apns.close().wait()
                try group.syncShutdownGracefully()
                
                self.switchConnectButton(isConnected: false)
                self.pushButton.isEnabled = false
            } catch {
                print(error)
            }
        }
    }
    
    @IBAction func pushAction(_ sender: Any) {
        
        guard let apns = self.apnsConnection else {
            return
        }
        
        self.deviceToken = self.deviceTokenTextField.stringValue
        
        guard let deviceToken = self.deviceToken else {
            return
        }
        
        self.pushTitle = self.titleTextField.stringValue
        self.pushSubtitle = self.subtitleTextField.stringValue
        self.pushBody = self.bodyTextField.stringValue
        
        let payload = self.appDataTextField.stringValue
        
        guard let title = self.pushTitle, let body = self.pushBody else {
            return
        }
        
        struct BasicNotification: APNSwiftNotification {
            let payload: String
            let aps: APNSwiftPayload
            init(payload: String, aps: APNSwiftPayload) {
                self.payload = payload
                self.aps = aps
            }
        }
        
        do {
            
            let aps = APNSwiftPayload(alert: .init(title: title, subtitle: self.pushSubtitle ?? "", body: body), badge: 1, hasContentAvailable: true)
            try apns.send(BasicNotification(payload: payload, aps: aps), pushType: .alert, to: deviceToken).wait()
            self.errorLabel.stringValue = ""
            
        } catch {
            self.errorLabel.stringValue = "\(error)"
            print(error)
        }

    }
    
    private func switchConnectButton(isConnected: Bool) {
        self.connectButton.title = isConnected ? "Disconnect" : "Connect"
        self.connectButton.action = isConnected ? #selector(disconnectAction) : #selector(connectAction)
    }
    
}
