//
//  P12PushViewController.swift
//  PushTestTool
//
//  Created by Marco on 2020/11/3.
//

import Cocoa
import APNSwift
import NIO
import JWTKit

class P12PushViewController: NSViewController, NSMenuDelegate {
    
    @IBOutlet weak var certSelectPopUpButton: NSPopUpButton!
    @IBOutlet weak var envSelectPopUpButton: NSPopUpButton!
    @IBOutlet weak var passwordTextField: NSTextField!
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
        self.openPanel?.allowedFileTypes = ["p12"]
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
        
        guard let certPath = self.certFilePath else {
            return
        }
        
        var privateKey: [UInt8] = []
        var cert: [UInt8] = []
        let pass: [UInt8] = Array("123456".utf8)
        
        let passwrod = self.passwordTextField.stringValue
        let result = self.readPKSC12(p12Path: certPath, password: passwrod)
        privateKey = result.0
        cert = result.1
        
        self.bundelId = self.bundelIdTextField.stringValue
        
        guard let bundelId = self.bundelId else {
            return
        }
        
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        let environment: APNSwiftConfiguration.Environment = self.envSelectPopUpButton.selectedTag() == 1 ? .production : .sandbox
        do {
            let apnsConfig = try APNSwiftConfiguration(authenticationMethod:
                                                            .tls(keyBytes: privateKey, certificateBytes: cert, pemPassword: pass),
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
        
        let appData = self.appDataTextField.stringValue
        
        guard let title = self.pushTitle, let body = self.pushBody else {
            return
        }
        
        struct BasicNotification: APNSwiftNotification {
            let appdata: String
            let aps: APNSwiftPayload
            init(appdata: String, aps: APNSwiftPayload) {
                self.appdata = appdata
                self.aps = aps
            }
        }
        
        do {
            
            let aps = APNSwiftPayload(alert: .init(title: title, subtitle: self.pushSubtitle ?? "", body: body), badge: 1, hasContentAvailable: true)
            try apns.send(BasicNotification(appdata: appData, aps: aps), pushType: .alert, to: deviceToken).wait()
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
    
    private func readPKSC12(p12Path: String, password: String) -> ([UInt8], [UInt8]) {
        
        let pksc12Data = NSData.init(contentsOfFile: p12Path)
        guard let p12Data = pksc12Data else {
            return ([], [])
        }
        
        let importPasswordOption: NSDictionary = [kSecImportExportPassphrase as NSString: password]
        var items: CFArray?
        let importStatus: OSStatus = SecPKCS12Import(p12Data, importPasswordOption, &items)
        
        guard importStatus == errSecSuccess else {
            if importStatus == errSecAuthFailed {
                self.errorLabel.stringValue = "ERROR: SecPKCS12Import returned errSecAuthFailed. Incorrect password?"
                print("ERROR: SecPKCS12Import returned errSecAuthFailed. Incorrect password?")
            } else {
                self.errorLabel.stringValue = "SecPKCS12Import returned an error, status=\(importStatus)"
            }
            print("SecPKCS12Import returned an error, status=\(importStatus)")
            return ([], [])
        }
        
        guard let nsItems = items as NSArray? else {
            return ([], [])
        }
        
        guard let dictItem = nsItems.firstObject as? [String: Any] else {
            return ([], [])
        }
        
        let identity: SecIdentity = dictItem[kSecImportItemIdentity as String] as! SecIdentity
        
        var privateKey: SecKey?
        let keyStatus = SecIdentityCopyPrivateKey(identity, &privateKey)
        var secCertificate: SecCertificate?
        let certStatus = SecIdentityCopyCertificate(identity, &secCertificate)
        
        guard keyStatus == errSecSuccess else {
            self.errorLabel.stringValue = "get private key failed"
            return ([], [])
        }
        
        guard certStatus == errSecSuccess else {
            self.errorLabel.stringValue = "get cert failed"
            return ([], [])
        }
        
        guard let privKey = privateKey, let secCert = secCertificate else {
            return ([], [])
        }
        
        //var error: Unmanaged<CFError>?
        //let privKeyData = SecKeyCopyExternalRepresentation(privKey, &error) as NSData?
        
        var privKeyData: CFData?
        let pass = "123456" as CFString
        var exportParams = SecItemImportExportKeyParameters()
        exportParams.version = UInt32(SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION)
        exportParams.passphrase = Unmanaged.passRetained(pass)
        let privStatus = SecItemExport(privKey, .formatWrappedPKCS8, .pemArmour, &exportParams, &privKeyData)
        //let privKeyStr = (privKeyData as? NSData)?.base64EncodedString(options: .lineLength64Characters)
        
        var certificateData: CFData?
        let certDataStatus = SecItemExport(secCert, .formatUnknown, .pemArmour, nil, &certificateData)
        
        //let certData = SecCertificateCopyData(secCert) as NSData
        //let certStr = certData.base64EncodedString(options: .lineLength64Characters)
        
        guard privStatus == errSecSuccess,
              certDataStatus == errSecSuccess,
              let pKeyData: NSData = privKeyData,
              let certData: NSData = certificateData else {
            return ([], [])
        }
        
        let pKeyByteCount = pKeyData.length / MemoryLayout<UInt8>.size
        var pKeyByteArray = [UInt8](repeating: 0, count: pKeyByteCount)
        pKeyData.getBytes(&pKeyByteArray,length: pKeyByteCount)
        
        let certByteCount = certData.length / MemoryLayout<UInt8>.size
        var certByteArray = [UInt8](repeating: 0, count: certByteCount)
        certData.getBytes(&certByteArray,length: certByteCount)
        
        return (pKeyByteArray, certByteArray)
    }
    
}
