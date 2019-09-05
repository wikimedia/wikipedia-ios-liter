import UIKit
import WebKit


class ViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate {

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var webViewContainer: UIView!
    
    lazy var webViewConfiguration: WKWebViewConfiguration = {
        let contentController = WKUserContentController()
        let actionHandler = ActionHandlerScript()
        contentController.addUserScript(actionHandler)
        contentController.add(self, name: actionHandler.messageHandlerName)
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        configuration.userContentController = contentController
        return configuration
    }()
    
    lazy var webView: WKWebView = {
        let webView = WKWebView(frame: .zero, configuration: webViewConfiguration)
        webView.isHidden = true
        webView.navigationDelegate = self
        return webView
    }()
    
    let actionHandler = ActionHandlerScript()
    let fullPageBaseURL = "https://apps.wmflabs.org/en.wikipedia.org/v1/page/mobile-html/"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webViewContainer.addConstrainedSubview(webView)
        URLCache.shared.diskCapacity = 4000000000 // 4 GB
        URLCache.shared.memoryCapacity = 1000000000 // 1 GB
        URLCache.shared.removeAllCachedResponses()
        let websiteDataTypes: Set<String> = [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache]
        webViewConfiguration.websiteDataStore.removeData(ofTypes: websiteDataTypes, modifiedSince: Date.distantPast) {
            
        }
    }

    lazy var shellPagePath = "mobile-html-shell"
    lazy var shellPageURL = "https://talk-pages.wmflabs.org/en.wikipedia.org/v1/page/\(shellPagePath)"
    
    var isLoadingShell = false
    var isLoadingFull = false
    var isLoadingShellProgressively = false
    
    var articleTitle: String {
        return titleField.text ?? "United_States"
    }
    
    let loadCompletion = "() => { document.pcsActionHandler({action: 'setup'}) }"

    
    func loadArticleIntoShell(progressively: Bool = false) {
        let js: String
        if progressively {
            js = "pagelib.c1.Page.loadProgressively('https://en.wikipedia.org/api/rest_v1/page/mobile-html/\(articleTitle)', 100, \(loadCompletion))"
        } else {
            js = "pagelib.c1.Page.load('https://en.wikipedia.org/api/rest_v1/page/mobile-html/\(articleTitle)').then(() => { window.requestAnimationFrame(\(loadCompletion)) })"
        }
        markLoadStart()
        webView.evaluateJavaScript(js) { (_, error) in
            if let error = error {
                print("\(error)")
            }
        }
    }
    
    func loadShell(progressively: Bool = false) {
        webView.isHidden = true
        guard webView.url?.absoluteString.contains("/mobile-html-shell") ?? false else {
            isLoadingShell = true
            isLoadingShellProgressively = progressively
            webView.load(URLRequest(url: URL(string: shellPageURL)!))
            return
        }
        loadArticleIntoShell(progressively: progressively)
    }
    
    @IBAction func shell(_ sender: Any) {
        loadShell()
    }
    
    @IBAction func first(_ sender: Any) {
        loadShell(progressively: true)
    }
    
    @IBAction func full(_ sender: Any) {
        // trick webView into using the cache by loading a different URL first
        // loading the same URL twice forces it to ignore the cache
        isLoadingFull = true
        webView.load(URLRequest(url: URL(string: "about:blank")!))
    }
    
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
        switch action {
        case "preloaded":
            onPreload()
        case "setup":
            onSetup()
        case "postloaded":
            onPostLoad()
        default:
            break
        }
    }
    
    func onPreload() {

    }

    func onSetup() {
        markLoadEnd()
        webView.isHidden = false
    }
    
    func onPostLoad() {
    }
    
    private var loadStart: CFAbsoluteTime?
    private var loadEnd: CFAbsoluteTime?
    
    private func markLoadStart() {
        loadStart = CFAbsoluteTimeGetCurrent()
    }
    
    lazy var timeFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    private func markLoadEnd() {
        loadEnd = CFAbsoluteTimeGetCurrent()
        guard let start = loadStart, let end = loadEnd else {
            return
        }
        
        timeLabel.text = timeFormatter.string(from: NSNumber(floatLiteral: 1000 * (end - start)))
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if isLoadingShell {
            isLoadingShell = false
            webView.evaluateJavaScript("pagelib.c1.Page.setup(\(actionHandler.setupParams))") { (_, _) in
                self.loadArticleIntoShell(progressively: self.isLoadingShellProgressively)
            }
        } else if isLoadingFull {
            isLoadingFull = false
            let urlString = "\(fullPageBaseURL)\(articleTitle)"
            guard let url = URL(string: urlString) else {
                return
            }
            let request = URLRequest(url: url)
            webView.isHidden = true
            markLoadStart()
            webView.load(request)
        }
    }
        
}

