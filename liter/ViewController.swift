import UIKit

extension CharacterSet {
    static let pathComponentAllowed: CharacterSet = {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/.")
        return allowed
    }()
}
class ViewController: UIViewController, UIScrollViewDelegate, UITextFieldDelegate {
    @IBOutlet weak var languageField: UITextField!
    @IBOutlet weak var themeLabel: UILabel!
    @IBAction func showThemeList(_ sender: Any) {
        let pickerVC = PickerViewController(options: ["light", "dark", "sepia", "black"]) { [unowned self] (picked) in
            defer {
                self.dismiss(animated: true)
            }
            guard let picked = picked else {
                return
            }
            self.themeLabel.text = String(picked.prefix(1))
            self.pageViewControllerA.theme = picked
            self.pageViewControllerB.theme = picked
        }
        present(pickerVC, animated: true)
    }
    
    lazy var languages: [String] = {
        return ["hi", "he", "fa", "ru", "pl", "vi", "sv", "nl", "de", "en", "es", "fr", "it", "ja", "pt", "zh"].sorted()
    }()
    
    @IBAction func showLanguageList(_ sender: Any) {
        let pickerVC = PickerViewController(options: languages) { [unowned self] (picked) in
            defer {
                self.dismiss(animated: true)
            }
            guard let picked = picked else {
                return
            }
            self.languageField.text = picked
            self.titleField.text = ""
        }
        present(pickerVC, animated: true)
    }
    
    var language: String {
        return languageField.text ?? "en"
    }
    
    var pageLists: [String: [String]] = [:]
    
    @IBAction func showPageList(_ sender: Any) {
        var list = pageLists[language]
        if (list == nil) {
            guard let listURL = Bundle.main.url(forResource: language, withExtension: "txt") else {
                return
            }
            guard let file = try? String(contentsOf: listURL) else {
                return
            }
            list = file.split(separator: "\n").map { String($0) }
            pageLists[language] = list
        }
        guard let langList = list else {
            return
        }
        let pickerVC = PickerViewController(options: langList) { [unowned self] (picked) in
            defer {
                self.dismiss(animated: true)
            }
            guard let picked = picked else {
                return
            }
            self.titleField.text = picked
            self.load(with: picked) { (_) in
                
            }
        }
        present(pickerVC, animated: true)
        
    }

    
    public func load(with title: String, completion: @escaping (Result<TimeInterval, AppError>) -> Void) {
        let title = title.replacingOccurrences(of: " ", with: "_");
        guard let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: CharacterSet.pathComponentAllowed) else {
            return
        }
        let a = "https://apps.wmflabs.org/"
        let b = "https://apps2.wmflabs.org/"
        let basePath = "\(language).wikipedia.org/v1/page/mobile-html/"
        activityIndicator.startAnimating()
        let loadGroup = DispatchGroup()
        loadGroup.enter()
        pageViewControllerA.load(with: URL(string: a + basePath + encodedTitle)!) { (result) in
            loadGroup.leave()
        }
        loadGroup.enter()
        pageViewControllerB.load(with: URL(string: b + basePath + encodedTitle)!) { (result) in
            loadGroup.leave()
        }
        loadGroup.notify(queue: DispatchQueue.main) {
            self.activityIndicator.stopAnimating()
        }
    }
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var webViewContainer: UIView!
    @IBOutlet weak var secondWebViewContainer: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet var controls: [UIControl]!
    @IBOutlet var textFields: [UITextField]!
    
    var articleTitle: String = "United_States"
    
    lazy var pageViewControllerA: PageViewController = {
        return PageViewController()
    }()
    lazy var pageViewControllerB: PageViewController = {
        return PageViewController()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(pageViewControllerA)
        webViewContainer.addConstrainedSubview(pageViewControllerA.view)
        pageViewControllerA.didMove(toParent: self)
        
        addChild(pageViewControllerB)
        secondWebViewContainer.addConstrainedSubview(pageViewControllerB.view)
        pageViewControllerB.didMove(toParent: self)
        
        pageViewControllerA.webView.scrollView.delegate = self
        pageViewControllerB.webView.scrollView.delegate = self

        URLCache.shared.diskCapacity = 4000000000 // 4 GB
        URLCache.shared.memoryCapacity = 1000000000 // 1 GB
        URLCache.shared.removeAllCachedResponses()
        webViewContainer.backgroundColor = UIColor.thermosphere
        
        for field in textFields {
            field.returnKeyType = .go
            field.delegate = self
        }
    }
    

    
    @IBAction func standardProgressive(_ sender: Any) {
        titleField.endEditing(true)
        languageField.endEditing(true)
        load(with: titleField.text!) { (_) in
            
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView === pageViewControllerA.webView.scrollView {
            pageViewControllerB.webView.scrollView.contentOffset = scrollView.contentOffset
        } else {
            pageViewControllerA.webView.scrollView.contentOffset = scrollView.contentOffset
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard string != "\n" else {
            standardProgressive(self)
            return false
        }
        return true
    }
}


