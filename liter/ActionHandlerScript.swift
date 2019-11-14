import WebKit

final class ActionHandlerScript: WKUserScript   {
    required init(theme: String, messageHandlerName: String, interfaceName: String) {
        let themeClass: String
        if interfaceName == "pcs" {
            themeClass = "pcs-theme-\(theme.lowercased())"
        } else {
            themeClass = "pagelib_theme_\(theme.lowercased())"
        }
        let setupParams: String = "{theme: '\(themeClass)', margins: {top: '16px', right: '16px', bottom: '16px', left: '16px'}, areTablesInitiallyExpanded: true}"
        let source = """
        document.pcsActionHandler = (action) => {
          window.webkit.messageHandlers.\(messageHandlerName).postMessage(action)
        };
        document.pcsSetupSettings = \(setupParams);
        """
        super.init(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }
}
