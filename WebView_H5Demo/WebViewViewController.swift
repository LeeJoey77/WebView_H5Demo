//
//  WebViewViewController.swift
//  WebView_H5Demo
//
//  Created by admin on 2018/5/11.
//  Copyright © 2018年 admin. All rights reserved.
//

import UIKit
import JavaScriptCore

class WebViewViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var webView: UIWebView!
    var context: JSContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        context = webView.value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as! JSContext
        setNavBar()
        loadURL()
    }
    
    func setNavBar() {
        navigationItem.title = "JS_Native"
        let btnBack = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(toBack))
        navigationItem.leftBarButtonItem = btnBack
    }
    
    @objc func toBack() {
        //webView 可以返回则返回上一页
        if self.webView.canGoBack {
            self.webView.goBack()
        }else {
            //不能返回返回原生代码
            navigationController?.popViewController(animated: true)
        }
    }
    
    //加载网页
    func loadURL() {
        let url = Bundle.main.url(forResource: "WebView", withExtension: "html")
        let request = NSURLRequest(url: url! as URL)
        webView.loadRequest(request as URLRequest)
        
    }
    
    //MARK: **************************** Native 调用 JS 方式一
    //直接注入:
    // Swift 调用JS 方法 （无参数）
    //这个方法是一个同步方法，会阻塞当前线程！尽管此方法不被弃用，最佳做法是使用 WKWebView 类的 evaluateJavaScript：completionHandler：method。
    @IBAction func swift_js_nopara(_ sender: UIButton) {
        context.evaluateScript("Swift_JS1()")
        //或
//        self.webView.stringByEvaluatingJavaScriptFromString("Swift_JS1()")
    }
    
    // Swift 调用JS 方法 （有参数)
    @IBAction func swift_js_para(_ sender: UIButton) {
        context.evaluateScript("Swift_JS2('oc' ,'Swift')")
        //或
// self.webView.stringByEvaluatingJavaScriptFromString("Swift_JS2('oc','swift')")
        
        //方式二:
//        native_jsMethodTwo()
        
    }
    
    //MARK: **************************** Native 调用 JS 方式二
    //JavaScriptCore:
    func native_jsMethodTwo() {
        // 如果涉及 UI 操作，切回主线程调用 JS 代码中的 YourFuncName，通过数组@[parameter] 入参
        let jsValue: JSValue = self.context.objectForKeyedSubscript("Swift_JS2")
        jsValue.call(withArguments: ["oc" ,"Swift"])
    }
    
    deinit {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension WebViewViewController {
    //MARK: --------------------------- JS 调用 Native 方式一
    //假请求方式:
    //用JS发起一个假的URL请求，然后利用UIWebView的代理方法拦截这次请求, 然后在 shouldStartLoadWith 方法中做相应的处理, 要传递参数时, 可以拼接在url上
    //注意:
    //1. JS中的firstClick,在拦截到的url scheme全都被转化为小写
    //2. html中需要设置编码，否则中文参数可能会出现编码问题
    //3. JS用打开一个iFrame的方式替代直接用document.location的方式, 以避免多次请求, 被替换覆盖的问题
    //4. 要传递参数时, 可以拼接在url上
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {

        if (request.url?.absoluteString.contains("Http_request"))! {
            //TODO:
            shareAction(message: "方式一")
            return false
        }
        return true
    }
    
    func shareAction(message: String) {
        let alert = UIAlertController.init(title: "JS 调用 Native", message: message, preferredStyle: . alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) -> Void in
        }))
        self.present(alert, animated: true, completion: nil)
    
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        
        //MARK: --------------------------- JS 调用 Native 方式二
        //Block 方式:
        //使用 block 在js中运行原生代码, 将自动与JavaScript方法建立桥梁
        //需要注意: 这种方法仅仅适用于 OC 的 block, 并不适用于swift中的闭包, 为了公开闭包, 我们将进行如下两步操作:
        //(1）使用 @convention(block) 属性标记闭包，来建立桥梁成为 OC 中的 block
        //(2）在映射 block 到 JavaScript方法调用之前，我们需要 unsafeBitCast 函数将 block 转成为 AnyObject
        
        // JS调用了无参数swift方法
        let temp1: @convention(block) () ->() = {
            self.menthod1()
        }
        self.context.setObject(unsafeBitCast(temp1, to: AnyObject.self), forKeyedSubscript: "test1" as NSCopying & NSObjectProtocol)

        // JS调用了有参数swift方法
        let temp2: @convention(block) () ->() = {
            let array = JSContext.currentArguments() // 这里接到的array中的内容是JSValue类型
            for object in array! {
                print(object)
            }
            self.menthod2(str1: (array![0] as AnyObject).toString(), str2: (array![1] as AnyObject).toString())
        }
        self.context.setObject(unsafeBitCast(temp2, to: AnyObject.self), forKeyedSubscript: "test2" as NSCopying & NSObjectProtocol)
        

        //MARK: --------------------------- JS 调用 Native 方式三
        //JSExport protocol方式:
        //(1）首先必须创建一个协议遵守JSExport协议，并声明想暴露在JavaScript中的属性和方法。
        //(2）对于每一个暴露给JavaScript的原生类，JavaScriptCore都将在 JSContext中创建一个标准
        
        // 模型注入
        let model = JSObjCModel()
        model.controller = self
        model.jsContext = context
        // 这一步是将OCModel这个模型注入到JS中，在JS就可以通过OCModel调用我们暴露的方法了
        context.setObject(model, forKeyedSubscript: "OCModel" as NSCopying & NSObjectProtocol)
        let url = Bundle.main.url(forResource: "WebView", withExtension: "html")
        context.evaluateScript(try? String.init(contentsOf: url!, encoding: .utf8))
        context.exceptionHandler = { [unowned self](con, except) in
            self.context.exception = except
        }
    }
    
    func menthod1() {
        DispatchQueue.main.async() { () -> Void in
            let alert = UIAlertController(title: "JS调用了无参数swift方法", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func menthod2(str1: String, str2: String) {
        DispatchQueue.main.async() { () -> Void in
            let alert = UIAlertController(title: "JS调用了有参swift方法", message: "参数为\(str1),\(str2)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        
    }
}

//MARK: ---------------------- JSExport协议:
//可以使用该协议暴露原生对象，实例方法，类方法，和属性给JavaScript，这样JavaScript就可以调用相关暴露的方法和属性。遵守JSExport协议，就可以定义我们自己的协议，在协议中声明的API都会在JS中暴露出来
@objc protocol JavaScriptSwiftDelegate: JSExport {
    func callNoParam()
    
    func showAlert(_ title: String, msg: String)
    
    func callWithDict(_ dict: [String: AnyObject])
    
    func callHandler(_ handleFuncName: String)
}

@objc class JSObjCModel: NSObject, JavaScriptSwiftDelegate {
    weak var controller: UIViewController?
    weak var jsContext: JSContext?
    
    func callNoParam() {
        let jsFunc = self.jsContext?.objectForKeyedSubscript("jsFunc");
        _ = jsFunc?.call(withArguments: []);
    }
    
    //注意: 如果js是多个参数的话  我们代理方法的所有变量前的名字连起来要和js的方法名字一样
    //比如: js方法为  OCModel.showAlertMsg('js title', 'js message')
    //他有两个参数 那么我们的代理方法 就是把js的方法名 showAlertMsg 任意拆分成两段作为代理方法名
    //第一个参数的 argumentLabel 用 "_" 隐藏
    func showAlert(_ title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler: nil))
        self.controller?.present(alert, animated: true, completion: nil)
    }
    
    func callWithDict(_ dict: [String : AnyObject]) {
        let alert = UIAlertController(title: dict["name"] as? String, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler: nil))
        self.controller?.present(alert, animated: true, completion: nil)
    }
    
    func callHandler(_ handleFuncName: String) {
        let jsParamFunc = self.jsContext?.objectForKeyedSubscript(handleFuncName);
        let dict = NSDictionary(dictionary: ["age": 18, "height": 168, "name": "lili"])
        _ = jsParamFunc?.call(withArguments: [dict])
    }
}

