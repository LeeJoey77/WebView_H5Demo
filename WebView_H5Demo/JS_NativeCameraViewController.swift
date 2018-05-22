//
//  JS_NativeCameraViewController.swift
//  WebView_H5Demo
//
//  Created by admin on 2018/5/16.
//  Copyright © 2018年 admin. All rights reserved.
//

import UIKit
import JavaScriptCore

//@objc 必须写, 否则 JS 代码找不到对于方法
@objc protocol JSDelegate: JSExport {
    //第一个参数的 argumentLabel 用 "_" 隐藏
    func getImage(_ parameter: Any)
}

class JS_NativeCameraViewController: UIViewController, JSDelegate, UIWebViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {//UINavigationControllerDelegate,UIImagePickerControllerDelegate 这两个代理是打开系统相机的代理
    
    @IBOutlet weak var webView: UIWebView!
    var jsContext: JSContext!
    private var indexNumb: Int!
    private var pickedImage: UIImage!

    override func viewDidLoad() {
        super.viewDidLoad()
        loadURL()
    }

    //加载网页
    func loadURL() {
        let url = Bundle.main.url(forResource: "JSNativeCamera", withExtension: "html")
        let request = NSURLRequest(url: url! as URL)
        webView.loadRequest(request as URLRequest)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension JS_NativeCameraViewController {
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        return true
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        jsContext = webView.value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as! JSContext
        jsContext.setObject(self, forKeyedSubscript: "CameraModel" as NSCopying & NSObjectProtocol)
        let url = Bundle.main.url(forResource: "JSNativeCamera", withExtension: "html")
        jsContext.evaluateScript(try? String.init(contentsOf: url!, encoding: .utf8))
        jsContext.exceptionHandler = { [unowned self](context, except) in
            self.jsContext.exception = except
            print("获取 self.jsContext 异常信息 \(String(describing: except))");
        }
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        
    }
    
    func getImage(_ parameter: Any) {
        let jsonStr = "\(parameter)"
        let tempDic:[String: Any]? = try? JSONSerialization.jsonObject(with: jsonStr.data(using: .utf8)!, options: .allowFragments) as! Dictionary
        if let jsDic = tempDic {
            print(jsDic)
            for (key, value) in jsDic {
                print(key, value)
            }
            beginOpenPhoto()
        }
    }
    
    func beginOpenPhoto() {
        DispatchQueue.main.async {
            //拍照
            self.takePhoto()
            //相册
//            self.openLocalPhoto()
        }
    }
    
    //MARK: ------------------------- UIImagePickerControllerDelegate
    //取消选择
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    //选择完成
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        //选择的类型是照片
        let type = info[UIImagePickerControllerMediaType] as! String
        if type == "public.image" {
            //获取照片
            pickedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
            print(pickedImage.size)
            // obtainImage 压缩图片 返回原尺寸
            indexNumb = (indexNumb == 1 ? 2 : 1)
            let nameStr = "Varify\(indexNumb!).jpg"
            SaveImage_Util.saveImage(saveImage: pickedImage, imageName: nameStr) { (path) in
                let jsValue = self.jsContext.objectForKeyedSubscript("setImageWithPath")
                _ = jsValue?.call(withArguments: [["imagePath": path, "iosContent":"获取图片成功，把系统获取的图片路径传给js 让html显示"]])
//                DispatchQueue.main.async {
//                    //这里是IOS 调 js 其中 setImageWithPath 就是js中的方法 setImageWithPath(),参数是字典
//                }
            }
            picker.dismiss(animated: true, completion: nil)
        }
    }
    
    //打开本地相册
    func openLocalPhoto() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        self.present(imagePicker, animated: true, completion: nil)
    }
 
    //打开相机拍照
    func takePhoto() {
        let sourceType = UIImagePickerControllerSourceType.camera
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = sourceType
            picker.allowsEditing = true
            picker.modalTransitionStyle = .coverVertical
            self.present(picker, animated: true, completion: nil)
        }else {
            let alert = UIAlertController(title: "提示", message: "模拟器不能打开相机", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}



















