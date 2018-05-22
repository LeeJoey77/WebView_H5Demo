//
//  SaveImage_Util.swift
//  WebView_H5Demo
//
//  Created by admin on 2018/5/16.
//  Copyright © 2018年 admin. All rights reserved.
//

import UIKit

class SaveImage_Util: NSObject {

    static func saveImage(saveImage: UIImage, imageName: String, backHandler: @escaping (_ imagePath: String) -> ()) {
        let path = self.getImageDocumentFolderPath()
        let imageData: NSData? = UIImagePNGRepresentation(saveImage)! as NSData
        let documentsDirectory = "\(path + "/pic")/" as NSString
        let imagePath = documentsDirectory.appendingPathComponent(imageName)
        let fileManager = FileManager.default
        let isExist = fileManager.fileExists(atPath: imagePath)
        if isExist {
           //存在删除
            do {
                try fileManager.removeItem(atPath: imagePath)
            }catch {
                
            }
            if (imageData?.write(toFile: imagePath, atomically: true))! {
                backHandler(imagePath)
            }
        }else {
            do {
                try fileManager.createDirectory(atPath: path + "/pic", withIntermediateDirectories: true, attributes: nil)
            }catch {
                
            }
            if (imageData?.write(toFile: imagePath, atomically: true))! {
                backHandler(imagePath)
            }
            
        }
    }
    
    //Document 路径
    static func getImageDocumentFolderPath() -> String {
        let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first!
        print(path)
        return path
    }
}
