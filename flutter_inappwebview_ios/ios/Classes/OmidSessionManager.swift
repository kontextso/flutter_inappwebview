import Foundation
import WebKit
import OMSDK_Megabrainco

@available(iOS 11.0, *) public class OmidSessionManager: ChannelDelegate {
    static let methodChannelName = "kontext_omid"
    private var sessions: [String: OmidSessionState] = [:]

    private struct OmidSessionState {
        weak var webView: InAppWebView?
        let adSession: OMIDMegabraincoAdSession
    }

    init ? (plugin: SwiftFlutterPlugin) {
        guard let registrar = plugin.registrar else {
            return nil
        }
        let channel = FlutterMethodChannel(name: OmidSessionManager.methodChannelName, binaryMessenger: registrar.messenger())
        super.init(channel: channel)
    }

    public override func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any?] else {
            result(FlutterError(code: "invalid_arguments", message: "Expected argument map.", details: nil))
            return
        }

        switch call.method {
        case "startOmidSession":
            startSession(arguments: arguments, result: result)
        case "stopOmidSession":
            stopSession(arguments: arguments, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func disposeSessions() {
        DispatchQueue.main.async {
            for state in self.sessions.values {
                state.adSession.finish()
            }
            self.sessions.removeAll()
        }
    }

    private func startSession(arguments: [String: Any?], result: @escaping FlutterResult) {
        guard let instanceId = arguments["instanceId"] as? String, !instanceId.isEmpty else {
            result(FlutterError(code: "missing_instance_id", message: "Expected a non-empty instanceId.", details: nil))
            return
        }
        guard sessions[instanceId] == nil else {
            result(FlutterError(code: "duplicate_session", message: "An OMID session already exists for instanceId \(instanceId).", details: nil))
            return
        }
        guard let webView = WebViewInstanceRegistry.get(instanceId: instanceId) else {
            result(FlutterError(code: "webview_not_found", message: "No WebView found for instanceId \(instanceId).", details: nil))
            return
        }
        guard let partnerName = arguments["partnerName"] as? String, !partnerName.isEmpty,
        let partnerVersion = arguments["partnerVersion"] as? String, !partnerVersion.isEmpty else {
            result(FlutterError(code: "invalid_partner", message: "partnerName and partnerVersion are required.", details: nil))
            return
        }
        if let customReferenceData = arguments["customReferenceData"] as? String, customReferenceData.count > 256 {
            result(FlutterError(code: "invalid_custom_reference_data", message: "customReferenceData must be 256 characters or fewer.", details: nil))
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard self.sessions[instanceId] == nil else {
                result(FlutterError(code: "duplicate_session", message: "An OMID session already exists for instanceId \(instanceId).", details: nil))
                return
            }
            guard self.ensureOmidActivated(result: result) else {
                return
            }
            let partner = OMIDMegabraincoPartner(name: partnerName, versionString: partnerVersion)
            guard let partner = partner else {
                result(FlutterError(code: "session_start_failed", message: "Failed to create OMID partner instance.", details: nil))
                return
            }

            let contentUrl = arguments["contentUrl"] as? String
            let customReferenceData = arguments["customReferenceData"] as? String
            do {

                let adSessionContext = try OMIDMegabraincoAdSessionContext(
                    partner: partner,
                    webView: webView,
                    contentUrl: contentUrl,
                    customReferenceIdentifier: customReferenceData
                )

                let adSessionConfiguration = try OMIDMegabraincoAdSessionConfiguration(
                    creativeType: .htmlDisplay,
                    impressionType: .beginToRender,
                    impressionOwner: .javaScriptOwner,
                    mediaEventsOwner: .noneOwner,
                    isolateVerificationScripts: false
                )

                let adSession = try OMIDMegabraincoAdSession(
                    configuration: adSessionConfiguration,
                    adSessionContext: adSessionContext
                )

                adSession.mainAdView = webView
                adSession.start()
                self.sessions[instanceId] = OmidSessionState(webView: webView, adSession: adSession)
                result(true)
            } catch {
                result(FlutterError(code: "session_start_failed", message: "Failed to start OMID session.", details: error.localizedDescription))
            }
        }
    }

    private func stopSession(arguments: [String: Any?], result: @escaping FlutterResult) {
        guard let instanceId = arguments["instanceId"] as? String, !instanceId.isEmpty else {
            result(FlutterError(code: "missing_instance_id", message: "Expected a non-empty instanceId.", details: nil))
            return
        }
        DispatchQueue.main.async {
            if let state = self.sessions.removeValue(forKey: instanceId) {
                state.adSession.finish()
                result(true)
            } else {
                result(FlutterError(code: "session_not_found", message: "No OMID session for instanceId \(instanceId).", details: nil))
            }
        }
    }


    private func ensureOmidActivated(result: @escaping FlutterResult) -> Bool {
        let sdk = OMIDMegabraincoSDK.shared
        if sdk.isActive {
            return true
        }
        if sdk.activate() {
            return true
        }
        result(FlutterError(code: "omid_activation_failed", message: "Failed to activate OM SDK.", details: nil))
        return false
    }
}
