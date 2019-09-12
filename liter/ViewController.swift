import UIKit
import WebKit


class ViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate {
    enum LoadType {
        case standard
        case shell
    }
    var loadType: LoadType = .shell
    enum LoadMode {
        case full
        case progressive
    }
    var loadMode: LoadMode = .full
    enum LoadState {
        case none
        case loading
        case loadingShell
        case loadingIntoShell
        case loaded
        case setup
    }
    var loadState: LoadState = .none {
        didSet {
            let loading = loadState != .none && loadState != .setup
            if loading {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
            titleField.isEnabled = !loading
            for control in controls {
                control.isEnabled = !loading
            }
        }
    }
    
    var loadedURLs: Set<URL> = []

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
    let fullPageBaseURL = "https://en.wikipedia.org/api/rest_v1/page/mobile-html/"
    
    lazy var shellPagePath = "mobile-html-shell"
    lazy var shellPageURL = "https://talk-pages.wmflabs.org/en.wikipedia.org/v1/page/\(shellPagePath)"
    let shellProgressiveFirstLoadCompletion = "() => { document.pcsActionHandler({action: 'shell_inital_load_complete'}) }"
    let shellProgressiveFullLoadCompletion = "() => { document.pcsActionHandler({action: 'shell_full_load_complete'}) }"
    
    let shellFullLoadCompletion = "() => { document.pcsActionHandler({action: 'shell_load_complete'}) }"

    var articleTitle: String = "United_States"
    var articleURL: URL?  {
        return URL(string: "\(fullPageBaseURL)\(articleTitle)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webViewContainer.addConstrainedSubview(webView)
        URLCache.shared.diskCapacity = 4000000000 // 4 GB
        URLCache.shared.memoryCapacity = 1000000000 // 1 GB
        URLCache.shared.removeAllCachedResponses()
        let websiteDataTypes: Set<String> = [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache]
        webViewConfiguration.websiteDataStore.removeData(ofTypes: websiteDataTypes, modifiedSince: Date.distantPast) {
            
        }
        webView.backgroundColor = UIColor.thermosphere
        webViewContainer.backgroundColor = UIColor.thermosphere
    }

    func loadArticleIntoShell(with url: URL) {
        loadState = .loadingIntoShell
        let js: String
        if loadMode == .progressive {
            js = "pagelib.c1.Page.loadProgressively('\(url.absoluteString)', 100, \(shellProgressiveFirstLoadCompletion), \(shellProgressiveFullLoadCompletion))"
        } else {
            js = "pagelib.c1.Page.load('\(url.absoluteString)').then(() => { window.requestAnimationFrame(\(shellFullLoadCompletion)) })"
        }
        markLoadStart()
        webView.evaluateJavaScript(js) { (_, error) in
            if let error = error {
                print("\(error)")
            }
        }
    }
    
    func loadShell() {
        guard loadType == .shell && loadState == .setup else {
            loadType = .shell
            loadState = .loadingShell
            webView.isHidden = true
            webView.load(URLRequest(url: URL(string: shellPageURL)!))
            return
        }
        loadState = .loadingIntoShell
        guard let url = articleURL else {
            return
        }
        loadArticleIntoShell(with: url)
    }
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet var controls: [UIControl]!
    
    @IBAction func shellFull(_ sender: Any) {
        articleTitle = titleField.text!
        loadMode = .full
        loadShell()
    }
    
    @IBAction func shellFirst(_ sender: Any) {
        articleTitle = titleField.text!
        loadMode = .progressive
        loadShell()
    }
    
    @IBAction func standardProgressive(_ sender: Any) {
        // trick webView into using the cache by loading a different URL first
        // loading the same URL twice forces it to ignore the cache
        articleTitle = titleField.text!
        loadType = .standard
        loadMode = .progressive
        loadState = .loading
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
        let data = body["data"] as? [String: Any]
        switch action {
        case "preloaded":
            onPreload()
        case "setup":
            onSetup()
        case "postloaded":
            onPostLoad()
        case "link_clicked":
            guard let href = data?["href"] as? String else {
                break
            }
            onLinkClicked(href: href)
        case "shell_inital_load_complete":
            markLoadEnd()
            webView.isHidden = false
        case "shell_full_load_complete":
            loadState = .setup
            webView.evaluateJavaScript("pagelib.c1.Page.setup(\(self.actionHandler.setupParams))")
        case "shell_load_complete":
            markLoadEnd()
            webView.isHidden = false
            loadState = .setup
            webView.evaluateJavaScript("pagelib.c1.Page.setup(\(self.actionHandler.setupParams))")
        default:
            break
        }
    }
    
    func onLinkClicked(href: String) {
        guard href.hasPrefix("./") else {
            return
        }
        let title = String(href.suffix(href.count - 2))
        articleTitle = title
        guard let articleURL = articleURL else {
            return
        }
        switch loadType {
        case .shell:
            loadArticleIntoShell(with: articleURL)
        default:
            markLoadStart()
            webView.load(URLRequest(url: articleURL))
        }
    }
    
    
    func onPreload() {

    }

    func onSetup() {
        webView.isHidden = false
        guard loadState != .setup else {
            markLoadEnd()
            return
        }
        guard loadType == .shell else {
            loadState = .setup
            markLoadEnd()
            return
        }
        guard let articleURL = articleURL else {
            return
        }
        loadArticleIntoShell(with: articleURL)
    }
    
    func onPostLoad() {
    }
    
    private var loadStart: CFAbsoluteTime?
    private var loadEnd: CFAbsoluteTime?
    
    private func markLoadStart() {
        timeLabel.text = "..."
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
        guard let articleURL = articleURL else {
            return
        }
        let cached: String
        if loadedURLs.contains(articleURL) {
            cached = "cached"
        } else {
            cached = "uncached"
            loadedURLs.insert(articleURL)
        }
        timeLabel.text = "\(timeFormatter.string(from: NSNumber(floatLiteral: 1000 * (end - start))) ?? "") \(cached)"
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if loadType == .shell && loadState == .loadingShell {
            loadState = .loaded
            webView.evaluateJavaScript("""
                pagelib.c1.InteractionHandling.setInteractionHandler((action) => {
                    window.webkit.messageHandlers.\(self.actionHandler.messageHandlerName).postMessage(action)
                })
            """) { (_, _) in
                webView.evaluateJavaScript("pagelib.c1.Page.setup(\(self.actionHandler.setupParams), () => { window.webkit.messageHandlers.\(self.actionHandler.messageHandlerName).postMessage({action: 'setup'}) }) ") { (_, _) in
                }
            }
            
        } else if loadType == .standard && loadState == .loading {
            loadState = .loaded
            guard let articleURL = articleURL else {
                return
            }
            let request = URLRequest(url: articleURL)
            webView.isHidden = true
            markLoadStart()
            webView.load(request)
        }
    }
        
}

