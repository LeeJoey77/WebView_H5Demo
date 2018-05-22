//
//  ViewController.swift
//  WebView_H5Demo
//
//  Created by admin on 2018/5/9.
//  Copyright © 2018年 admin. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func toFirstVC(_ sender: UIButton) {
        //iOS与JS交互的方法:
        //1.假请求, 拦截url（适用于UIWebView和WKWebView）
        //2.JavaScriptCore（只适用于UIWebView，iOS7+）
        //3.WKScriptMessageHandler（只适用于WKWebView，iOS8+）
        //4.WebViewJavascriptBridge（适用于UIWebView和WKWebView，属于第三方框架）
        
        if sender.tag == 200 {
            let webViewVC = storyboard?.instantiateViewController(withIdentifier: "WebViewViewController")
            navigationController?.pushViewController(webViewVC!, animated: true)
        }else if sender.tag == 201 {
            let wkWebViewVC = storyboard?.instantiateViewController(withIdentifier: "WKWebViewViewController")
            navigationController?.pushViewController(wkWebViewVC!, animated: true)
        }else {
            let js_NativeCameraVC = storyboard?.instantiateViewController(withIdentifier: "JS_NativeCameraViewController")
            navigationController?.pushViewController(js_NativeCameraVC!, animated: true)
        }
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

