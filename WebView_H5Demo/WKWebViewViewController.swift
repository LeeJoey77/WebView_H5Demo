//
//  WKWebViewViewController.swift
//  WebView_H5Demo
//
//  Created by admin on 2018/5/11.
//  Copyright © 2018年 admin. All rights reserved.
//

import UIKit
import WebKit

class WKWebViewViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    
    var wkWebView: WKWebView!
    var progressView = UIProgressView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavBar()
        setWebView()
        setProgressView()
        loadURL()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //注入对象名称 APPModel, 当 JS 通过 APPModel 调用时, 可以在 WKScriptMessageHandler 代理方法中接收到
        wkWebView.configuration.userContentController.add(self, name: "APPModel")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        wkWebView.configuration.userContentController.removeScriptMessageHandler(forName: "APPModel")
    }
    
    func setNavBar() {
        navigationItem.title = "JS_Native"
        let btnBack = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(toBack))
        navigationItem.leftBarButtonItem = btnBack
    }
    
    @objc func toBack() {
        if self.wkWebView.canGoBack {
            self.wkWebView.goBack()
        }else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    func setWebView() {
        //创建配置类
        let confirgure = WKWebViewConfiguration()
        //配置偏好设置
        confirgure.preferences = WKPreferences()
        //默认为 0
        confirgure.preferences.minimumFontSize = 10
        //默认为 true
        confirgure.preferences.javaScriptEnabled = true
        //在 iOS 上默认为 false, 表示不能自动通过窗口打开
        confirgure.preferences.javaScriptCanOpenWindowsAutomatically = false
        
        //配置Js与Web内容交互:
        //WKUserContentController内容交互控制器
        //WKUserContentController 调用 add(_ scriptMessageHandler:, name: String) 给JS注入对象
        //注入对象后, JS端就可以使用 window.webkit.messageHandlers.<name>.postMessage(<messageBody>)来调用发送数据给iOS端
        //比如: window.webkit.messageHandlers.APPModel.postMessage({body: '发送数据给 iOS 端'})
        //对象注入写在 viewWillAppear 中, 防止循环引用

        confirgure.userContentController = WKUserContentController()
        
        //创建WKWebView
        wkWebView = WKWebView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height), configuration: confirgure)
        
        //配置代理
        wkWebView.navigationDelegate = self as WKNavigationDelegate
        wkWebView.uiDelegate = self as WKUIDelegate
        
        //是否支持左、右swipe手势是否可以前进、后退
        wkWebView.allowsBackForwardNavigationGestures = true
        view.addSubview(wkWebView)
        
        //底部按钮调用 Native_JS
        let button = UIButton.init(frame: CGRect(x: 0, y: UIScreen.main.bounds.size.height - 120, width: 100, height: 45))
        button.center.x = view.center.x
        button.backgroundColor = .cyan
        button.setTitle("Native_JS", for: .normal)
        button.setTitleColor(.blue, for: .normal)
        button.addTarget(self, action: #selector(native_jsAction(_:)), for: .touchUpInside)
        view.addSubview(button)
    }
    
    //设置进度条
    //UIWebView 无法获取网页加载进度,于是也就无法创建进度条了,当然我们可以以某种算法模拟网页加载,自己设置进度条的值。
    //WKWebView提供了获取网页加载进度的方法,支持KVO,也就是estimatedProgress。
    //另外还有loading是否正在加载和title页面标题
    func setProgressView() {
        progressView = UIProgressView(frame: CGRect(x: 0, y: 65, width: view.frame.width, height: 30))
        progressView.progress = 0.0
        progressView.tintColor = .blue
        wkWebView.addSubview(progressView)
        
        //添加 KVO 监听
        wkWebView.addObserver(self, forKeyPath: "loading", options: .new, context: nil)
        wkWebView.addObserver(self, forKeyPath: "title", options: .new, context: nil)
        wkWebView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            progressView.alpha = 1.0
            progressView.setProgress(Float(wkWebView.estimatedProgress), animated: true)
            //进度条的值最大为1.0
            if(wkWebView.estimatedProgress >= 1.0) {
                UIView.animate(withDuration: 0.3, delay: 0.1, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseInOut, animations: { () -> Void in
                    self.progressView.alpha = 0.0
                }) { (finished:Bool) -> Void in
                    self.progressView.progress = 0
                }
            }
        }else if keyPath == "loading" {
            print(keyPath!, object!, change!)
        }else if keyPath == "title" {
            title = wkWebView.title
        }
    }
    
    //加载网页
    func loadURL() {
        let url = Bundle.main.url(forResource: "WKWebView", withExtension: "html")
        let request = NSURLRequest(url: url! as URL)
        wkWebView.load(request as URLRequest)
    }
    
    //Native 调用 JS
    @objc func native_jsAction(_ sender: UIButton) {
        native_Js()
    }
    
    deinit {
        wkWebView.removeObserver(self, forKeyPath: "estimatedProgress")
        wkWebView.removeObserver(self, forKeyPath: "loading")
        wkWebView.removeObserver(self, forKeyPath: "title")
        wkWebView.uiDelegate = nil
        wkWebView.navigationDelegate = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension WKWebViewViewController {
    //MARK: --------------------- WKNavigationDelegate
    //处理web导航操作, 比如链接跳转、接收响应, 在导航开始、成功、失败等时要做些处理
    
    //请求开始前,会先调用此代理方法
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        //MARK: --------------------------- JS 调用 Native 方式一
        //假 Request 方法(同 UIWebView):
        //要传递参数时, 可以拼接在url上
        if (navigationAction.request.url?.absoluteString.contains("Http_request"))! {
            decisionHandler(.cancel)
            let alert = UIAlertController(title: "To do something", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) -> Void in
                
            }))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        //点击链接跳转
        let hostname = navigationAction.request.url?.host?.lowercased()
        if navigationAction.navigationType == .linkActivated && !(hostname?.contains(".pottermore.com"))! {
            decisionHandler(WKNavigationActionPolicy.cancel)
        }else {
            UIApplication.shared.open(navigationAction.request.url!, options: [:], completionHandler: nil)
            decisionHandler(WKNavigationActionPolicy.allow)
        }
    }
    
    //在响应完成时会调用此方法
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(WKNavigationResponsePolicy.allow)
    }
    
    //开始导航跳转
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {

    }
    
    //接收到重定向时
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
    }
    
    //页面内容到达 main frame 时调用
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        
        
    }
    
    //导航完成调用, 页面加载完成
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        navigationItem.title = webView.title
    }
    
    //导航失败
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        
        
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        //加载失败隐藏进度条
        progressView.isHidden = true
        
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        completionHandler(URLSession.AuthChallengeDisposition.performDefaultHandling, nil)
    }
    
    //web 内容处理中断时触发
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        
    }
    
    //MARK: --------------------------- JS 调用 Native 方式二
    //WKUIDelegate 协议:
    //与JS 的 alert、confirm、prompt交互, 弹出的实际上是我们原生的窗口,在得到数据后, 由原生传回到JS
    func webViewDidClose(_ webView: WKWebView) {
        
    }
    
    //JS 端调用 alert
    //通过 message 得到JS 端所传的数据,在得到原生结果后, 需要回调 JS, 通过 completionHandler
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: "Alert", message: "JS 调用 alert", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) -> Void in
            completionHandler()
        }))
        self.present(alert, animated: true, completion: nil)
        print(#function, message)
    }
    
    //JS 端调用 confirm
    //通过 message 得到JS 端所传的数据,在 ios 端显示原生 alert 得到 true/false 后通过 completionHandler 回调给 JS
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "Confirm", message: "JS 调用 confirm", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) -> Void in
            completionHandler(true)
        }))
        alert.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (_) -> Void in
            completionHandler(false)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    //JS 端调用 prompt
    //要求输入一段文本, 在ios 端原生输入得到文本后通过 completionHandler 回调给 JS
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: "TextInput", message: "JS 调用输入框", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.textColor = .blue
        }
        alert.addAction(UIAlertAction(title: "ok", style: .default, handler: { (_) -> Void in
            completionHandler(alert.textFields?.last?.text)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func webView(webView: WKWebView, createWebViewWithConfiguration configuration: WKWebViewConfiguration, forNavigationAction navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        //如果目标主视图不为空,则允许导航
        if !(navigationAction.targetFrame?.isMainFrame != nil) {
            wkWebView.load(navigationAction.request)
        }
        return nil
    }
    
    //MARK: --------------------------- JS 调用 Native 方式三
    //WKScriptMessageHandler 协议:
    //JS 通过 AppModel 给 Native 发送数据，会在该方法中收到
    //JS调用iOS的部分, 都只能在此处使用, 我们也可以注入多个名称（JS对象), 用于区分功能
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "APPModel" {
            //传递的参数只支持NSNumber, NSString, NSDate, NSArray,NSDictionary, and NSNull类型
            let alert = UIAlertController(title: "MessageHandler", message: message.name, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) -> Void in
                
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

extension WKWebViewViewController {
    
    //MARK: **************************** Native 调用 JS 方式一
    //直接注入:
    func native_Js() {
        let jsStr = "callJsConfirm()"
        wkWebView.evaluateJavaScript(jsStr) { (result, error) in
            print(result, error)
        }
    }
}

















