import Foundation

class CacheOperation: AsyncOperation, StreamDelegate {
    let request: URLRequest
    let callback: Callback<URLResponse, Error>
    init(request: URLRequest, callback: Callback<URLResponse, Error>) {
        self.request = request
        self.callback = callback
    }
    
    var inputStream: InputStream!
    var expectedContentLength: Int = 0
    override func execute() {
        let maybeFileURL: URL?
        switch request.url?.path {
        case "/api/rest_v1/page/mobile-html/United_States":
            maybeFileURL = Bundle.main.url(forResource: "United States", withExtension: "html")!
        default:
            maybeFileURL = nil
        }
        guard
            let fileURL = maybeFileURL,
            let stream = InputStream(url: fileURL)
        else {
            finish(with: AppError.generic)
            return
        }
        let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .typeIdentifierKey])
        let headerFields: [String: String] = [
            "Content-Type": "text/html; charset=utf-8; profile=\"https://www.mediawiki.org/wiki/Specs/\"",
            "Content-Length": "\(values?.fileSize ?? -1)"
        ]
        guard let response = HTTPURLResponse(url: request.url ?? URL(string: "about:blank")!, statusCode: 200, httpVersion: nil, headerFields: headerFields) else {
            finish(with: AppError.generic)
            return
        }
        callback.response?(response)
        
        inputStream = stream
        inputStream.delegate = self
        inputStream.schedule(in: RunLoop.main, forMode: .common)
        inputStream.open()
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .hasBytesAvailable:
            var data = Data()
            let bufferSize = 1024
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            while inputStream.hasBytesAvailable {
                let read = inputStream.read(buffer, maxLength: bufferSize)
                expectedContentLength += read
                data.append(buffer, count: read)
            }
            callback.data?(data)
        case .endEncountered:
            callback.success()
        case .errorOccurred:
            callback.failure(aStream.streamError ?? AppError.generic)
        default:
            break
        }
    }
    
    override func finish(with error: Error) {
//        var response = HTTPURLResponse(url: request.url ?? URL(string: "about:blank")!, statusCode: 404, httpVersion: nil, headerFields: nil)
//        callback.response?(fourOhFourResponse)
        callback.failure(error)
        super.finish(with: error)
    }
}

//class Cache {
//    let path: String
//    let session: Session
//    init(path: String, session: Session) {
//        self.session = session
//    }
//    
//    let queue: OperationQueue = {
//        let q = OperationQueue()
//        q.maxConcurrentOperationCount = 4
//        return q
//    }()
//    
//    func dataTaskWith(_ request: URLRequest, callback: Callback<URLResponse, Error>) -> CacheOperation {
//        let op = CacheOperation(request: request, callback: callback)
//        queue.addOperation(op)
//        return op
//    }
//    
//    func add(_ url: URL) {
//        session.downloadTask(with: url) { (fileURL, response, error) in
//            
//        }
//    }
//}
