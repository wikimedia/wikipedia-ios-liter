import WebKit

final class ActionHandlerScript: WKUserScript   {
    let setupParams: String = "{theme: 'pagelib_theme_dark', loadImages: false, margins: {top: '16px', right: '16px', bottom: '16px', left: '16px'}}"
    let messageHandlerName: String = "action"
    override init() {
        let source = """
        document.pcsActionHandler = (action) => {
          window.webkit.messageHandlers.\(messageHandlerName).postMessage(action)
        };
        document.pcsSetupSettings = \(setupParams);
        """
        super.init(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }
}
