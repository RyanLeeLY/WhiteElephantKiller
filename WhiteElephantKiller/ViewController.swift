//
//  ViewController.swift
//  WEKMethodScanner
//
//  Created by Yao Li on 2018/7/16.
//  Copyright © 2018年 yaoli. All rights reserved.
//

import Cocoa

private let WhiteListString = " set|.cxx_destruct|^PB|^RLM|^WX|^RAC|^MAS|^SD|^AF|^NMC|^NIM|^NELive|^POP|^QQ|^VTMagicView|^JSON|^BaiduMob|^GPUImage|^LOT|^YY|^Agora|^DTHTML|^WMPageController|^VKVideo|^FMDatabase|^FMResultSet|^NSObject(LKModel)|^GDT|^HmtObj|^TYAlert|^RSK|^WF|^TPU|^WT|^MBProgress|^KAD|^ZFPlayer|^NGMovie|^Hy|^BLY|^TPLog|^LS|^NSDate(DateTools)|^WXApi|^IDM|^DT|^VGT|^XHInput|^MKAnnotationView|^RDVTabBar|^GCD|^WalkieTalkie|^NSString(WTExtend)|^MJRefresh|^A2Dynamic|^A2BlockInvocation|^ASI|^NSObject(POP)|^NSProxy(POP)|^NSString(HyEncode)|^NSString(MJExtensionDeprecated_v_2_5_16)|^NSObject(MJKeyValueDeprecated_v_2_5_16)|^FLAnimatedImage|^SVProgressHUD|^WapAuthHandler|^WeChatApiUtil|^udp_request_t|^AGBannerView|^AppCommunicateData|^udp_response_t|^XMLParser|^WKWebViewJavascriptBridge|^TZImage|^TTT|^TPNHTTP|^SeattleFeatureExecutor|^DBHelper|^DataBaseModel|^DateTimeUtil|yy_|bk_|sd_|LOT_|mj_|rac_|rdv_|mas_|LKDB|ASValue|iv_| tableView:| collectionView:| numberOfSectionsInCollectionView:| scrollView|POP|VKMsgSend| searchBar| textView:| pageViewController:| gestureRecognizer:| TPRouter_|view$|View$"

private let LinkMapFilePathUserDefaultsKey = "LinkMapFilePathUserDefaultsKey"
private let AppFilePathUserDefaultsKey = "AppFilePathUserDefaultsKey"

class ViewController: NSViewController {
    
    @IBOutlet weak var linkMapChooseButton: NSButton!
    @IBOutlet weak var appFileChooseButton: NSButton!
    @IBOutlet weak var startButton: NSButton!
    
    @IBOutlet weak var linkMapTextField: NSTextField!
    @IBOutlet weak var appFileTextField: NSTextField!
    
    @IBOutlet weak var resultTextView: NSTextView!
    
    @IBOutlet weak var scanInfoTextField: NSTextField!
    @IBOutlet weak var scanProgressIndicator: NSProgressIndicator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scanProgressIndicator.stopAnimation(nil)
        
        if let linkMapFilePath = UserDefaults.standard.string(forKey: LinkMapFilePathUserDefaultsKey) {
            self.linkMapTextField.stringValue = linkMapFilePath
        }
        
        if let appFilePath = UserDefaults.standard.string(forKey: AppFilePathUserDefaultsKey) {
            self.appFileTextField.stringValue = appFilePath
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(receiveNewScanInfo(_ :)), name: NSNotification.Name(WEKMethodScannerNewInfoNotification), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(receiveNewScanProgress(_ :)), name: NSNotification.Name(WEKMethodScannerProgressNotification), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(receiveSaveDocNotification(_ :)), name: NSNotification.Name(AppDelegateSaveDocumentNotification), object: nil)
    }
    
    @objc func receiveNewScanInfo(_ notification: Notification) {
        DispatchQueue.main.async {
            self.scanInfoTextField.stringValue = notification.userInfo?[NSLocalizedDescriptionKey] as! String
        }
    }
    
    @objc func receiveNewScanProgress(_ notification: Notification) {
        let total = notification.userInfo![WEKMethodScannerProgressTotalCountKey] as! Double
        let currentCount = notification.userInfo![WEKMethodScannerProgressCurrentCountKey] as! Double
        let doubleValue = currentCount * 100/total
        
        DispatchQueue.main.async {
            if (total == currentCount) {
                self.scanProgressIndicator.stopAnimation(nil)
            } else {
                self.scanProgressIndicator.startAnimation(nil)
            }
            self.scanProgressIndicator.doubleValue = doubleValue
        }
    }
    
    @objc func receiveSaveDocNotification(_ notification: Notification) {
        NSSavePanel.tpm_quickSave(in: self.view.window, nameField: "FilePath", message: "Export File") { (res, panel) in
            if (res == .OK) {
                let data = self.resultTextView.string.data(using: String.Encoding.utf8)
                try? data?.write(to: panel.url!)
            }
        }
    }
    
    @IBAction func actionFromButton(_ sender: NSButton) {
        if (sender == self.appFileChooseButton) {
            NSOpenPanel.tpm_quickOpen(in: self.view.window!, nameField: "APP", message: "Choose a APP File") { (res, panel) in
                if res == .OK {
                    if let title = panel.url?.path {
                        UserDefaults.standard.set(title, forKey: AppFilePathUserDefaultsKey)
                        self.appFileTextField.stringValue = title
                    }
                }
            }
        } else if (sender == self.linkMapChooseButton) {
            NSOpenPanel.tpm_quickOpen(in: self.view.window!, nameField: "Link Map", message: "Choose a LinkMap File") { (res, panel) in
                if res == .OK {
                    if let title = panel.url?.path {
                        UserDefaults.standard.set(title, forKey: LinkMapFilePathUserDefaultsKey)
                        self.linkMapTextField.stringValue = title
                    }
                }
            }
        } else if (sender == self.startButton) {
            self.startButton.title = "Analysing"
            self.startButton.isEnabled = false
            let linkMapFilePath = self.linkMapTextField.stringValue
            let appFilePath = self.appFileTextField.stringValue
            
            DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
                
                let jsonData = try! JSONSerialization.data(withJSONObject: WEKMethodScanner.start(linkMapFilePath, asmFilePath: appFilePath, whiteListRex: WhiteListString), options: JSONSerialization.WritingOptions.prettyPrinted)
                
                DispatchQueue.main.async {
                    if let resultString = String(data: jsonData, encoding: String.Encoding.utf8) {
                        self.resultTextView.string = resultString
                    }
                    
                    self.startButton.title = "Start"
                    self.startButton.isEnabled = true
                }
            }
        }
        
        
    }
    
}

