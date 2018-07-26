//
//  AppDelegate.swift
//  WEKMethodScanner
//
//  Created by Yao Li on 2018/7/16.
//  Copyright © 2018年 yaoli. All rights reserved.
//

import Cocoa

let AppDelegateSaveDocumentNotification = "AppDelegateSaveDocumentNotification"


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if (flag) {
            return false
        } else {
            sender.unhide(nil)
            return true
        }
    }
    
    @IBAction func saveDocument(_ sender: NSMenuItem) {
        NotificationCenter.default.post(name: NSNotification.Name(AppDelegateSaveDocumentNotification), object: nil)
    }
}

