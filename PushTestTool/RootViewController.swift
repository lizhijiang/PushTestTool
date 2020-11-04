//
//  ViewController.swift
//  PushTestTool
//
//  Created by Marco on 2020/10/30.
//

import Cocoa

class RootViewController: NSViewController {
    
    let p8ViewController: P8PushViewController = P8PushViewController()
    let p12ViewController: P12PushViewController = P12PushViewController()
    
    public func switchContent(index: Int) {
        if index == 0 {
            self.p12ViewController.view.isHidden = true
            self.p8ViewController.view.isHidden = false
        } else if (index == 1) {
            self.p12ViewController.view.isHidden = false
            self.p8ViewController.view.isHidden = true
        }
    }
    
    override func loadView() {
        self.view = NSView()
        
        self.view.addSubview(p8ViewController.view)
        p8ViewController.view.autoresizingMask = [.width, .height]
        p8ViewController.view.frame = self.view.bounds
        self.addChild(p8ViewController)
        
        self.view.addSubview(p12ViewController.view)
        p12ViewController.view.autoresizingMask = [.width, .height]
        p12ViewController.view.frame = self.view.bounds
        self.addChild(p12ViewController)
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "PushTestTool"
        
        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

