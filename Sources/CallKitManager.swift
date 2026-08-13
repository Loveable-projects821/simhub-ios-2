import Foundation
import CallKit
import AVFoundation

/// Wraps CallKit so an incoming "ringing" event from the Android hub shows a real
/// native incoming-call screen on the iPhone (lock screen, Bluetooth/CarPlay routing, etc).
///
/// IMPORTANT — read this before wiring up real audio:
/// This class only presents the CALL UI. It does not yet carry any audio.
/// Answering here should be the trigger that starts your WebRTC audio session
/// (Phase 2) between this app and the Android hub — CallKit itself doesn't provide
/// audio transport, it just gives you the system call screen and routes whatever
/// audio session you activate in `provider(_:didActivate:)`.
final class CallKitManager: NSObject, CXProviderDelegate {

    static let shared = CallKitManager()

    private let provider: CXProvider
    private let callController = CXCallController()
    private var activeCallUUID: UUID?

    /// Called when the user answers on iPhone — hook your WebRTC call start here.
    var onAnswer: (() -> Void)?
    /// Called when the user ends/rejects — hook your WebRTC call teardown here.
    var onEnd: (() -> Void)?

    override init() {
        let config = CXProviderConfiguration()
        config.supportsVideo = false
        config.maximumCallsPerCallGroup = 1
        config.supportedHandleTypes = [.phoneNumber]
        provider = CXProvider(configuration: config)
        super.init()
        provider.setDelegate(self, queue: nil)
    }

    /// Call this when HubConnection.onIncomingCall fires.
    func reportIncomingCall(from number: String) {
        let uuid = UUID()
        activeCallUUID = uuid

        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .phoneNumber, value: number)
        update.hasVideo = false

        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            if let error = error {
                print("SimHub: failed to report incoming call — \(error.localizedDescription)")
            }
        }
    }

    /// Call this when the Android side reports the real call ended, so the
    /// iPhone's CallKit screen clears itself too.
    func endReportedCall() {
        guard let uuid = activeCallUUID else { return }
        provider.reportCall(with: uuid, endedAt: nil, reason: .remoteEnded)
        activeCallUUID = nil
    }

    // MARK: - CXProviderDelegate

    func providerDidReset(_ provider: CXProvider) {
        activeCallUUID = nil
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        action.fulfill()
        onAnswer?()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        action.fulfill()
        activeCallUUID = nil
        onEnd?()
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        // Phase 2: start feeding your WebRTC audio engine using this session.
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        // Phase 2: tear down the WebRTC audio engine.
    }
}
