//
//  AppDelegate.swift
//  PushTestTool
//
//  Created by Marco on 2020/10/30.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        let rootViewController = RootViewController()
        let pushTypeViewController = PushTypeViewController.init { index in
            rootViewController.switchContent(index: index)
        }
        
        let splitViewController = NSSplitViewController.init()
        splitViewController.addSplitViewItem(NSSplitViewItem.init(sidebarWithViewController: pushTypeViewController))
        splitViewController.addSplitViewItem(NSSplitViewItem.init(viewController: rootViewController))
        splitViewController.title = "PushTestTool"
        splitViewController.view.frame = CGRect(x: 0, y: 0, width: 700, height: 500)
        
        self.window = NSWindow.init(contentViewController: splitViewController)
        self.window?.minSize = CGSize(width: 700, height: 500)
        self.window?.maxSize = CGSize(width: 700, height: 500)
        self.window?.makeKeyAndOrderFront(self)
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

