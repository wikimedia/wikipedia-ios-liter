import UIKit
import WebKit

class PageViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
    private var loadCompletion: ((Result<TimeInterval, AppError>) -> Void)? = nil
    
    public func load(with url: URL, completion: @escaping (Result<TimeInterval, AppError>) -> Void) {
        loadCompletion = completion
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    lazy var session: Session = {
        assert(Thread.isMainThread)
        return Session()
    }()
    
    lazy var schemeHandler: SchemeHandler = {
        assert(Thread.isMainThread)
        return SchemeHandler(scheme: "app", session: session)
    }()
    
    lazy var webViewConfiguration: WKWebViewConfiguration = {
        let contentController = WKUserContentController()
        let actionHandler = ActionHandlerScript()
        contentController.addUserScript(actionHandler)
        contentController.add(self, name: actionHandler.messageHandlerName)
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        configuration.setURLSchemeHandler(schemeHandler, forURLScheme: schemeHandler.scheme)
        configuration.userContentController = contentController
        return configuration
    }()
    
    lazy var webView: WKWebView = {
        let webView = WKWebView(frame: .zero, configuration: webViewConfiguration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        return webView
    }()
    
    override func loadView() {
        view = webView
        webView.backgroundColor = UIColor.thermosphere
        let websiteDataTypes: Set<String> = [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache]
        webViewConfiguration.websiteDataStore.removeData(ofTypes: websiteDataTypes, modifiedSince: Date.distantPast) {
            
        }
        webView.backgroundColor = UIColor.thermosphere
    }
    
    let actionHandler = ActionHandlerScript()
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == actionHandler.messageHandlerName else {
            return
        }
        guard let body = message.body as? [String: Any] else {
            return
        }
        guard let action = body["action"] as? String else {
            return
        }
        let data = body["data"] as? [String: Any]
        switch action {
        case "preloaded":
            onPreload()
        case "setup":
            onSetup()
        case "final_setup":
            onPostLoad()
        case "link_clicked":
            guard let href = data?["href"] as? String else {
                break
            }
            onLinkClicked(href: href)
        default:
            break
        }
    }
    
    func onLinkClicked(href: String) {
        guard href.hasPrefix("./") else {
            return
        }
        print(href)
        //        let title = String(href.suffix(href.count - 2))
        //
        //        pageTitle = title
        //        guard let pageURL = pageURL else {
        //            return
        //        }
        //        switch loadType {
        //        case .shell:
        //            loadPageIntoShell(with: pageURL)
        //        default:
        //            markLoadStart()
        //            webView.load(URLRequest(url: pageURL))
        //        }
    }
    
    
    func onPreload() {
        
    }
    
    func onSetup() {
        loadCompletion?(.success(0))
        loadCompletion = nil
    }
    
    func onPostLoad() {
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
    }
    
}

