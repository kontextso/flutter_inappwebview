import Foundation

final class WebViewInstanceRegistry {
    private struct WeakInAppWebView {
        weak var value: InAppWebView?
    }

    private static var registry: [String: WeakInAppWebView] = [:]
    private static let lock = NSObject()

    private init() {}

    static func register(instanceId: String, webView: InAppWebView) {
        objc_sync_enter(lock)
        removeStaleReferencesLocked(for: webView)
        registry[instanceId] = WeakInAppWebView(value: webView)
        objc_sync_exit(lock)
    }

    static func unregister(instanceId: String, webView: InAppWebView?) {
        objc_sync_enter(lock)
        if let entry = registry[instanceId] {
            if let registered = entry.value {
                if webView == nil || registered === webView {
                    registry.removeValue(forKey: instanceId)
                }
            } else {
                registry.removeValue(forKey: instanceId)
            }
        }
        objc_sync_exit(lock)
    }

    static func unregister(webView: InAppWebView) {
        objc_sync_enter(lock)
        removeStaleReferencesLocked(for: webView)
        objc_sync_exit(lock)
    }

    static func get(instanceId: String) -> InAppWebView? {
        objc_sync_enter(lock)
        let webView = registry[instanceId]?.value
        if webView == nil {
            registry.removeValue(forKey: instanceId)
        }
        objc_sync_exit(lock)
        return webView
    }

    static func getRegisteredInstanceIds() -> [String] {
        objc_sync_enter(lock)
        cleanUpLocked()
        let keys = Array(registry.keys)
        objc_sync_exit(lock)
        return keys
    }

    static func isRegistered(instanceId: String) -> Bool {
        return get(instanceId: instanceId) != nil
    }

    static func clear() {
        objc_sync_enter(lock)
        registry.removeAll()
        objc_sync_exit(lock)
    }

    private static func cleanUpLocked() {
        let keysToRemove = registry.compactMap { (key: String, value: WeakInAppWebView) -> String? in
            return value.value == nil ? key : nil
        }
        for key in keysToRemove {
            registry.removeValue(forKey: key)
        }
    }

    private static func removeStaleReferencesLocked(for webView: InAppWebView) {
        let keysToRemove = registry.compactMap { (key: String, value: WeakInAppWebView) -> String? in
            guard let registered = value.value else {
                return key
            }
            return registered === webView ? key : nil
        }
        for key in keysToRemove {
            registry.removeValue(forKey: key)
        }
    }
}