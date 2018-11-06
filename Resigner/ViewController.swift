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
    private var consoleVc: ConsoleViewController?
    
    private var keyToDelete = ["jodogameid","jodocpid","jodochannelid","jodoLcClientKey","jodoLcAppId","jodoAppID","gamigameid","gamicpid","gamichannelid","gamiLcClientKey","gamiLcAppId","gamiAppID"]
    private var imageExtension = ["jpg","jpeg","png"]
    
    private var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter
    }()
    
    private var ipaDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH:mm"
        return dateFormatter
    }()
    
    
    //MARK: - IBOutlet
    
    @IBOutlet weak var resignCheckBox: NSButton!
    @IBOutlet weak var infoCheckBox: NSButton!
    @IBOutlet weak var sdkCheckBox: NSButton!
    @IBOutlet weak var gameLanguage: NSPopUpButtonCell!
    
    
    @IBOutlet weak var mainFloderField: NSTextField!
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
        
        let mainFolder = try? Folder(path: mainFloderField.stringValue)
        var ipaFile =  try? File(path: ipaField.stringValue)
        var cerFile = try? File(path: certificateField.stringValue)
        var provisionFile = try? File(path: provisionField.stringValue)
        var framewokFile = try? Folder(path: sdkFrameworkField.stringValue)
        var bundleFile = try? Folder(path: sdkBundleField.stringValue)
        var imageFolder = try? Folder(path: imageFolderField.stringValue)
        var plistFile = try? File(path: plistField.stringValue)
        guard let _ = dateFormatter.date(from: reviewDate.stringValue) else {
            showAlert(text: "强制审核日期不合法，请按yyyy-MM-dd HH:mm:ss 格式输入。\n 例：2018-08-10 18:30:00")
            return
        }
        
        if mainFloderField.stringValue != "" {
            ipaFile = mainFolder?.fileWithExtension("ipa")
            cerFile = mainFolder?.fileWithExtension("p12")
            provisionFile = mainFolder?.fileWithExtension("mobileprovision")
            framewokFile = mainFolder?.folderWithExtension("framework")
            bundleFile = mainFolder?.folderWithExtension("bundle")
            imageFolder = findImageFolder(in: mainFolder!)
            plistFile = mainFolder?.fileWithExtension("plist")
        }
        
        
        //check params
        if ipaFile == nil {
            showAlert(text: "无法找到游戏包文件")
            return
        }
        if isResign && (cerFile == nil || provisionFile == nil) {
            showAlert(text: "无法找到签名证书及provision file文件")
            return
        }
        if isReplaceSdk && (framewokFile == nil || bundleFile == nil) {
            showAlert(text: "无法找到SDK framework及bundle文件")
            return
        }
        if isReplaceInfo && plistFile == nil {
            showAlert(text: "无法找到plist文件")
            return
        }
        
//        presentViewControllerAsModalWindow(consoleVc!)
        
        // consoleVc?.appendText("开始重打包... \n")
        
        
        //unzip ipa
        var ipaFolder = try? Folder(path: (ipaFile!.parent?.path)! + (ipaFile?.nameExcludingExtension)!)
        if ipaFolder == nil {
            ipaFolder = try! ipaFile!.parent?.createSubfolderIfNeeded(withName: (ipaFile?.nameExcludingExtension)!)
            // consoleVc?.appendText("ipa解压中... \n")
            SSZipArchive.unzipFile(atPath: ipaFile!.path, toDestination: (ipaFolder?.path)!)
        }
        guard let folder = try? ipaFolder?.subfolder(named: "Payload").folderWithExtension("app"),
            let appFolder = folder else {
            showAlert(text: "异常：找不到app文件夹")
            return
        }
        
        let oldName = appFolder.name
        try? appFolder.rename(to: appFolder.name.replacingOccurrences(of: " ", with: ""))
        
        if imageFolder != nil {
            // consoleVc?.appendText("替换图片中... \n")
            replaceImage(imageFolder: imageFolder!, appFolder: appFolder)
        }
        
        if isReplaceSdk {
            // consoleVc?.appendText("替换SDK... \n")
            if !replaceSdk(frameworkFolder: framewokFile!, bundleFolder: bundleFile!, appFolder: appFolder) {
                return
            }
            // consoleVc?.appendText("替换SDK: \(framewokFile!.name), 替换Bundle: \(bundleFile!.name) 完成 \n")
        }
        
        if isReplaceInfo {
            // consoleVc?.appendText("替换info及加密文件... \n")
            if !replaceInfoPlist(plistFile: plistFile!, appFolder: appFolder) {
                return
            }
        }
        
        if isResign {
            // consoleVc?.appendText("重签名中... \n")
            if !resignApp(cerFile: cerFile!, provisionFile: provisionFile!, appFolder: appFolder, ipaFolder: ipaFolder!) {
                return
            }
        }
        
        try? appFolder.rename(to: oldName)
        // consoleVc?.appendText("正在生成游戏ipa... \n")
        let msg =  generateNewIpa(ipaFolder: ipaFolder!) ? "重打包完成:) \n" : "重打包失败！\n"
        showAlert(text: msg, style: .informational)
        // consoleVc?.appendText("\(msg) \n")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reviewDate.stringValue = dateFormatter.string(from: Date())
        gameLanguage.item(at: 0)?.title = "英文"
        gameLanguage.item(at: 1)?.title = "繁体"
        gameLanguage.item(at: 2)?.title = "简体"
        let storyboard = NSStoryboard(name: NSStoryboard.Name.init(rawValue: "Main") , bundle: nil)
        consoleVc = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier.init(rawValue: "console") ) as! ConsoleViewController
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    //MARK: - Method
    
    fileprivate func replaceImage(imageFolder: Folder, appFolder: Folder) {
        var replacedFile: [String] = []
        for image in imageFolder.files {
            guard let _ = try? appFolder.file(named: image.name) else { continue }
            image.copyOrReplace(to: appFolder)
            replacedFile.append(image.name)
        }
        if !replacedFile.isEmpty {
            // consoleVc?.appendText("成功替换以下图片文件: \n \(replacedFile) \n")
        }
    }
    
    fileprivate func replaceSdk(frameworkFolder: Folder, bundleFolder: Folder, appFolder: Folder) -> Bool {
        bundleFolder.copyOrReplace(to: appFolder)
        if let frameworksFolder = try? appFolder.subfolder(named: "Frameworks") {
            frameworkFolder.copyOrReplace(to: frameworksFolder)
            //检查是否含有模拟器框架
            var invaildFrameworksName: [String] = []
            for folder in frameworksFolder.subfolders {
                guard let file = try? folder.file(named: folder.nameExcludingExtension) else { continue }
                if let output = try? shellOut(to: "lipo -info \(file.path)"), (output.contains("i386") || output.contains("x86_64")) == true {
                    print(output)
                    invaildFrameworksName.append(file.name)
                }
            }
            if invaildFrameworksName.count > 0 {
                showAlert(text: "\(invaildFrameworksName) framework含有模拟器框架，请移除！！")
                return false
            }
        }
        return true
    }
    
    fileprivate func replaceInfoPlist(plistFile: File, appFolder: Folder) -> Bool {

        guard let gameInfo = NSMutableDictionary(contentsOfFile: plistFile.path),
                let infoFile = try? appFolder.file(named: "Info.plist"),
                  let info = NSMutableDictionary(contentsOfFile: infoFile.path)
        else {
            showAlert(text: "不能读取plist文件")
            return false
        }
        
        let data = try? JSONSerialization.data(withJSONObject: gameInfo, options: .prettyPrinted)
        let json = String.init(data: data!, encoding: .utf8)
        
        // consoleVc?.appendText("强制审核时间：\(reviewDate.stringValue) \n")
        // consoleVc?.appendText("加密文件内容：\(json as AnyObject) \n")
        
        //generate and replace encrypted file
        guard let date = dateFormatter.date(from: reviewDate.stringValue) else {
            showAlert(text: "强制审核时间格式不正确")
            return false
        }
        let plistParentFolder = (plistFile.parent)!
        var second = Int32(date.timeIntervalSince1970 - Date().timeIntervalSince1970)
        if second < 0 {
            second = 0
        }
        CreateGameInfo.createInfo(plistParentFolder.path, info: gameInfo as! [AnyHashable : Any], sec: second)
        if let encryptFile = try? plistParentFolder.file(named: "SSDaif") {
            encryptFile.copyOrReplace(to: appFolder)
        }
        
        _ = keyToDelete.map { info.setValue(nil, forKey: $0) }
        let bundleName = gameInfo["bundleName"] as? String ?? ""
        let facebookAppID = gameInfo["FacebookAppID"] as? String ?? ""
        info.setValue(gameInfo["appName"], forKey: "CFBundleDisplayName")
        info.setValue(gameInfo["facebookDisplayName"], forKey: "FacebookDisplayName")
        info.setValue(bundleName, forKey: "CFBundleIdentifier")
        info.setValue(gameInfo["bundleVersion"], forKey: "CFBundleVersion")
        info.setValue(gameInfo["bundleShortVersion"], forKey: "CFBundleShortVersionString")
        let whiteListSchemes = ["fb","fbapi","fb-messenger-api","fbauth2","djtellaw1230","fbshareextension","rficoswmcx","rtwsjdhsns","vjfjfmdldd"]
        info.setValue(whiteListSchemes, forKey: "LSApplicationQueriesSchemes")
        let urlScheme = ["fb"+facebookAppID,bundleName,"djmega1230."+bundleName,"djmega1230"]
        ((info.value(forKey: "CFBundleURLTypes") as? NSArray)?.firstObject as? NSDictionary)?.setValue(urlScheme, forKey: "CFBundleURLSchemes")
        
        if gameLanguage.selectedItem?.title == "英文" {
            info.setValue("Saving game account info and submitting screenshot while using customer service.", forKey: "NSPhotoLibraryAddUsageDescription")
            info.setValue("Saving game account info and submitting screenshot while using customer service.", forKey: "NSPhotoLibraryUsageDescription")
            info.setValue("Used to submit screenshots to the customer service when meet game problems or record game content of interest.", forKey: "NSCameraUsageDescription")
        }else if gameLanguage.selectedItem?.title == "繁体" {
            info.setValue("用於保存遊戲賬號信息及使用客服服務時提交問題截圖。", forKey: "NSPhotoLibraryAddUsageDescription")
            info.setValue("用於保存遊戲賬號信息及使用客服服務時提交問題截圖。", forKey: "NSPhotoLibraryUsageDescription")
            info.setValue("當遇到遊戲問題或感興趣的內容，用於拍攝照片提交至客服。", forKey: "NSCameraUsageDescription")
        }else if gameLanguage.selectedItem?.title == "简体" {
            info.setValue("用于保存游戏账号信息及使用客服服务时提交问题截图。", forKey: "NSPhotoLibraryAddUsageDescription")
            info.setValue("用于保存游戏账号信息及使用客服服务时提交问题截图。", forKey: "NSPhotoLibraryUsageDescription")
            info.setValue("当遇到游戏问题或感兴趣的内容，用于拍摄照片提交至客服。", forKey: "NSCameraUsageDescription")
        }
        
        if let debug = (info.value(forKey: "debug") as? Bool), debug {
            let documentType = ["public.plain-text ","public.text"]
            let documentTypeDic: [String: Any] = [
                "CFBundleTypeName" : "Debug File",
                "CFBundleTypeRole" : "Viewer",
                "LSHandlerRank" : "Owner",
                "LSItemContentTypes" : documentType
            ]
            info.setValue([documentTypeDic], forKey: "CFBundleDocumentTypes")
        }
        if !info.write(toFile: infoFile.path, atomically: true) {
            showAlert(text: "写入info.plist失败")
            return false
        }
        return true
    }
    
    fileprivate func resignApp(cerFile: File, provisionFile: File, appFolder: Folder, ipaFolder: Folder) -> Bool {

        let ipaFolderPath = ipaFolder.path
        let appPath = appFolder.path
        let frameworksPath = appFolder.path + "Frameworks"

        // consoleVc?.appendText("替换mobileprovision... \n")
        
        _ = try? shellOut(to: "cp \(provisionFile.path) \(appPath)/embedded.mobileprovision")
        
        // consoleVc?.appendText("生成entitlements... \n")

        _ = try? shellOut(to: "security cms -D -i \(appPath)/embedded.mobileprovision > \(ipaFolderPath)/t_entitlements_full.plist")
        _ = try? shellOut(to: "/usr/libexec/PlistBuddy -x -c \"Print:Entitlements\" \(ipaFolderPath)/t_entitlements_full.plist > \(ipaFolder.path)/entitlements.plist")
        try? ipaFolder.file(named: "t_entitlements_full.plist").delete()
        
        let output = try? shellOut(to: "openssl pkcs12 -info -in \(cerFile.path) -password pass: -passin pass: -passout pass:")
        var pattern = "iPhone\\sDistribution\\:[A-Za-z1-9\\s\\(]*\\)"
        var devId = regexGetFirstMatch(in: output!, with: pattern)
        if devId == nil {
            pattern = "iPhone\\sDeveloper\\:[A-Za-z1-9\\s\\(]*\\)"
            devId = regexGetFirstMatch(in: output!, with: pattern)
        }
        
        // consoleVc?.appendText("重签名frameworks... \n")
        
        let signFrameworkOutput = try? shellOut(to: "codesign -f -s \"\(devId!)\" \(ipaFolderPath)/entitlements.plist \(frameworksPath)/*")

        // consoleVc?.appendText("重签名App... \n")

        let signAppOutput = try? shellOut(to: "codesign -f -s \"\(devId!)\" --entitlements \(ipaFolderPath)/entitlements.plist \(appPath)")
        
        if signFrameworkOutput == nil || signAppOutput == nil {
            showAlert(text: "签名出错，请检查该签名证书是否已导入到本机")
            return false
        }
        try? ipaFolder.file(named: "entitlements.plist").delete()
        return true
    }
    
    fileprivate func generateNewIpa(ipaFolder: Folder) -> Bool {
        
        let payloadFolder = try? ipaFolder.subfolder(named: "Payload")
        let swiftSupportFolder = try? ipaFolder.subfolder(named: "SwiftSupport")
        if payloadFolder == nil {
            showAlert(text: "找不到Payload文件夹")
            return false
        }
        let iphoneosFolder = try? swiftSupportFolder?.subfolder(named: "iphoneos")
        if let folder = iphoneosFolder, let folder2 = folder, folder2.files.count < 1 {
            showAlert(text: "swiftsupport/iphoneos文件夹为空")
            return false
        }
        if let dsStoreFile = try? iphoneosFolder??.file(named: ".DS_Store") {
            try? dsStoreFile?.delete()
        }
        
        let outputFolder = try? ipaFolder.parent!.createSubfolderIfNeeded(withName: "导出包")
        let outputName = (outputFolder?.path)! + ipaDateFormatter.string(from: Date()) + ".ipa"
        
        
        let zipResult = SSZipArchive.createZipFile(atPath: outputName, withContentsOfDirectory: ipaFolder.path, keepParentDirectory: false)
        return zipResult
    }
    
    
    //MARK: - Helper Method
    
    fileprivate func showAlert(text: String, style: NSAlert.Style = .warning) {
        let alert = NSAlert()
        alert.informativeText = text
        alert.alertStyle = style
        alert.addButton(withTitle: "确认")
        alert.runModal()
    }
    
    fileprivate func regexGetFirstMatch(in text: String, with pattern: String) -> String? {
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        guard let match = regex?.matches(in: text, options: .withTransparentBounds, range: NSMakeRange(0, text.count))[0]
            else { return nil }
        return  (text as NSString).substring(with: match.range)
    }
    
    fileprivate func findImageFolder(in folder: Folder) -> Folder? {
        for subFolder in folder.subfolders {
            for file in subFolder.files {
                if let ext = file.extension?.lowercased(), imageExtension.contains(ext) {
                    return subFolder
                }
            }
        }
        return nil
    }
    
}

extension File {
    var fileUrl: URL {
        return URL(fileURLWithPath: self.path)
    }
    
    func copyOrReplace(to folder: Folder) {
        _ = try? folder.file(named: self.name).delete()
        _ = try? copy(to: folder)
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
    
    func copyOrReplace(to folder: Folder) {
        _ = try? folder.subfolder(named: self.name).delete()
        _ = try? copy(to: folder)
    }
}




