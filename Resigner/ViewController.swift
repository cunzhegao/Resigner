//
//  ViewController.swift
//  Resigner
//
//  Created by Kubrick.G on 2018/10/30.
//  Copyright © 2018年 kubrcik. All rights reserved.
//

import Cocoa
import SSZipArchive

class ViewController: NSViewController {

    //MARK: - Property
    
    private var isResign = true
    private var isReplaceInfo = true
    private var isReplaceSdk = true
    
    private var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter
    }()
    
    
    //MARK: - IBOutlet
    
    @IBOutlet weak var resignCheckBox: NSButton!
    @IBOutlet weak var infoCheckBox: NSButton!
    @IBOutlet weak var sdkCheckBox: NSButton!
    
    @IBOutlet weak var ipaField: NSTextField!
    @IBOutlet weak var certificateField: NSTextField!
    @IBOutlet weak var provisionField: NSTextField!
    @IBOutlet weak var sdkFrameworkField: NSTextField!
    @IBOutlet weak var sdkBundleField: NSTextField!
    @IBOutlet weak var imageFolderField: NSTextField!
    @IBOutlet weak var plistField: NSTextField!
    @IBOutlet weak var reviewDate: NSTextField!
    
    
    //MARK: - IBAction
    
    @IBAction func changResignCheckBox(_ sender: NSButton) {
        isResign = (sender.state == .on) ? true : false
    }
    
    
    @IBAction func changeInfoCheckBox(_ sender: NSButton) {
        isReplaceInfo = (sender.state == .on) ? true : false
    }
    
    
    @IBAction func changeSDKCheckBox(_ sender: NSButton) {
        isReplaceSdk = (sender.state == .on) ? true : false
    }
 
    
    @IBAction func startResign(_ sender: Any) {
        
        let ipaFile =  try? File(path: ipaField.stringValue) 
        let cerFile = try? File(path: certificateField.stringValue)
        let provisionFile = try? File(path: provisionField.stringValue)
        let framewokFile = try? Folder(path: sdkFrameworkField.stringValue)
        let bundleFile = try? Folder(path: sdkBundleField.stringValue)
        let imageFolderFile = try? Folder(path: imageFolderField.stringValue)
        let plistFile = try? File(path: plistField.stringValue)
        guard let date = dateFormatter.date(from: reviewDate.stringValue) else {
            showAlert(text: "强制审核日期不合法，请按yyyy-MM-dd HH:mm:ss 格式输入。/n 例：2018-08-10 18:30:00")
            return
        }
        
        //check params
//        if ipaFile == nil {
//            showAlert(text: "请输入游戏包目录")
//            return
//        }
//        if isResign && (cerFile == nil || provisionFile == nil) {
//            showAlert(text: "请输入签名证书及provision file目录")
//            return
//        }
//        if isReplaceSdk && (framewokFile == nil || bundleFile == nil) {
//            showAlert(text: "请输入SDK framework及bundle目录")
//            return
//        }
//        if isReplaceInfo && plistFile == nil {
//            showAlert(text: "请输入plist目录")
//            return
//        }
        
        //unzip ipa
        let ipaFolder = try? Folder(path: (ipaFile!.parent?.path)! + (ipaFile?.nameExcludingExtension)!)
        if ipaFolder == nil {
            let appFolder = try? ipaFile!.parent?.createSubfolderIfNeeded(withName: (ipaFile?.nameExcludingExtension)!)
            SSZipArchive.unzipFile(atPath: ipaFile!.path, toDestination: (appFolder??.path)!)
            print("asasdas")
        }
        guard let folder = try? ipaFolder?.subfolder(named: "Payload").folderWithExtension("app"),
            let appFolder = folder else {
            showAlert(text: "异常：找不到app文件夹")
            return
        }
        if imageFolderFile != nil {
            replaceImage(imageFolder: imageFolderFile!, appFolder: appFolder)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reviewDate.stringValue = dateFormatter.string(from: Date())
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    //MARK: - Method
    
    fileprivate func showAlert(text: String) {
        let alert = NSAlert()
        alert.informativeText = text
        alert.alertStyle = .warning
        alert.addButton(withTitle: "确认")
        alert.runModal()
    }
    
    fileprivate func replaceImage(imageFolder: Folder, appFolder: Folder) {
        let
        for file in imageFolder.files {
            
        }
    }
}

extension File {
    var fileUrl: URL {
        return URL(fileURLWithPath: self.path)
    }
}

extension Folder {
    var folderUrl: URL {
        return URL(fileURLWithPath: self.path)
    }
    
    func fileWithExtension(_ suffix: String) -> File? {
        for file in self.files {
            guard let ext = file.extension else  { continue }
            if ext == suffix {
                return file
            }
        }
        return nil
    }
    
    func folderWithExtension(_ suffix: String) -> Folder? {
        for folder in self.subfolders {
            guard let ext = folder.extension else  { continue }
            if ext == suffix {
                return folder
            }
        }
        return nil
    }
}




