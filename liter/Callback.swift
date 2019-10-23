import Foundation


public struct Callback<T, E> {
    let response: ((T) -> Void)?
    let data: ((Data) -> Void)?
    let success: (() -> Void)
    let failure: ((E) -> Void)
    
    public init(response: ((T) -> Void)?, data: ((Data) -> Void)?, success: @escaping () -> Void, failure: @escaping (E) -> Void) {
        self.response = response
        self.data = data
        self.success = success
        self.failure = failure
    }
}
