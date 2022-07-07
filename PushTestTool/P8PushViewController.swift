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

struct BasicNotification: APNSwiftNotification {
    let payload: String
    let aps: APNSwiftPayload
    init(payload: String, aps: APNSwiftPayload) {
        self.payload = payload
        self.aps = aps
    }
}

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
    
    var apnsConnection: APNSwiftConnection?
    var eventGroup: MultiThreadedEventLoopGroup?
    
    var lastEnv: APNSwiftConfiguration.Environment?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        envSelectPopUpButton.menu?.delegate = self
        switchConnectButton(isConnected: false)
        
    }
    
    override func viewDidAppear() {
        
    }
    
    override func viewDidDisappear() {
        
        errorLabel.stringValue = ""
        disconnectAction()
        
    }
    
    //MARK: NSMenuDelegate
    func menuWillOpen(_ menu: NSMenu) {
        lastEnv = envSelectPopUpButton.selectedTag() == 0 ? .sandbox : .production
    }
    
    func menuDidClose(_ menu: NSMenu) {
        let currentEnv: APNSwiftConfiguration.Environment = envSelectPopUpButton.selectedTag() == 0 ? .sandbox : .production
        if lastEnv == currentEnv {
            return
        }
        disconnectAction()
    }
    
    //MARK: Actions
    @IBAction func certSelectAction(_ sender: Any) {
        openPanel = NSOpenPanel()
        openPanel?.canChooseFiles = true
        openPanel?.canChooseDirectories = true
        openPanel?.allowedFileTypes = ["p8"]
        openPanel?.begin { [weak self] result in
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
        let keyId = keyIdTextField.stringValue
        let teamId = teamIdTextField.stringValue
        let bundelId = bundelIdTextField.stringValue
        
        guard let certPath = self.certFilePath else {
            errorLabel.stringValue = "cert path error!"
            return
        }
        
        guard keyId.count > 0, teamId.count > 0, bundelId.count > 0 else {
            errorLabel.stringValue = "params error!"
            return
        }
        
        errorLabel.stringValue = ""
        
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        let environment: APNSwiftConfiguration.Environment = envSelectPopUpButton.selectedTag() == 1 ? .production : .sandbox
        do {
            let apnsConfig = try APNSwiftConfiguration(authenticationMethod:
                                                            .jwt(key: .private(filePath: certPath),
                                                                 keyIdentifier: JWKIdentifier(string: keyId),
                                                                 teamIdentifier: teamId),
                                                        topic: bundelId,
                                                        environment: environment)
            
            apnsConnection = try APNSwiftConnection.connect(configuration: apnsConfig, on: group.next()).wait()
            eventGroup = group
            
            switchConnectButton(isConnected: true)
            pushButton.isEnabled = true
            errorLabel.stringValue = ""
            
        } catch {
            pushButton.isEnabled = false
            errorLabel.stringValue = "\(error)"
            print(error)
        }
        
    }
    
    @objc
    func disconnectAction() {
        if let group = eventGroup, let apns = apnsConnection {
            do {
                try apns.close().wait()
                try group.syncShutdownGracefully()
                
                switchConnectButton(isConnected: false)
                pushButton.isEnabled = false
            } catch {
                print(error)
            }
        }
    }
    
    @IBAction func pushAction(_ sender: Any) {
        
        guard let apns = apnsConnection else {
            errorLabel.stringValue = "no connection!"
            return
        }
        
        let deviceToken = deviceTokenTextField.stringValue
        
        guard deviceToken.count > 0 else {
            errorLabel.stringValue = "deviceToken empty!"
            return
        }
        
        let title = titleTextField.stringValue
        let pushSubtitle = subtitleTextField.stringValue
        let body = bodyTextField.stringValue
        
        let payload = appDataTextField.stringValue
        
        guard title.count > 0 else {
            return
        }
        
        do {
            
            let aps = APNSwiftPayload(alert: .init(title: title, subtitle: pushSubtitle, body: body), badge: 1, hasContentAvailable: true)
            try apns.send(BasicNotification(payload: payload, aps: aps), pushType: .alert, to: deviceToken).wait()
            errorLabel.stringValue = ""
            
        } catch {
            errorLabel.stringValue = "\(error)"
            print(error)
        }

    }
    
    private func switchConnectButton(isConnected: Bool) {
        connectButton.title = isConnected ? "Disconnect" : "Connect"
        connectButton.action = isConnected ? #selector(disconnectAction) : #selector(connectAction)
    }
    
}
