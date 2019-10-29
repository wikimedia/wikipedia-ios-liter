import WebKit

final class ActionHandlerScript: WKUserScript   {
    required init(theme: String, messageHandlerName: String) {
        let setupParams: String = "{theme: 'pagelib_theme_\(theme.lowercased())', margins: {top: '16px', right: '16px', bottom: '16px', left: '16px'}, areTablesInitiallyExpanded: true}"
        let source = """
        document.pcsActionHandler = (action) => {
          window.webkit.messageHandlers.\(messageHandlerName).postMessage(action)
        };
        document.pcsSetupSettings = \(setupParams);
        """
        super.init(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }
}
