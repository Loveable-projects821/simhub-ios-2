import Foundation
import WebRTC

/// Handles the actual live audio channel BETWEEN THE TWO APPS.
///
/// Scope, read this before assuming more than it does:
/// This carries audio between the iPhone app and the Android app's own mic/speaker —
/// a real, working VoIP call between the two devices. It does NOT and cannot carry
/// the voice of a third party on a real cellular call into or out of that call;
/// that path is blocked at the Android OS level on stock, non-rooted phones (see README).
final class WebRTCClient: NSObject {

    static let shared = WebRTCClient()

    private let factory: RTCPeerConnectionFactory
    private var peerConnection: RTCPeerConnection?
    private var localAudioTrack: RTCAudioTrack?
    weak var hub: HubConnection?

    private let mediaConstraints = RTCMediaConstraints(
        mandatoryConstraints: nil,
        optionalConstraints: ["DtlsSrtpKeyAgreement": "true"]
    )

    override init() {
        RTCInitializeSSL()
        let encoderFactory = RTCDefaultVideoEncoderFactory()
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        factory = RTCPeerConnectionFactory(encoderFactory: encoderFactory, decoderFactory: decoderFactory)
        super.init()
    }

    func attach(hub: HubConnection) {
        self.hub = hub
        hub.onWebRTCSignal = { [weak self] kind, json in
            self?.handleSignal(kind: kind, json: json)
        }
    }

    /// Called when the user answers the CallKit screen — starts our side of the call
    /// and waits for Android's offer (Android initiates since it detected the ring).
    func startAsAnswerer() {
        setupPeerConnection()
    }

    /// Called if the iPhone user places an outgoing call via the dialer — iPhone initiates.
    func startAsCaller() {
        setupPeerConnection()
        guard let pc = peerConnection else { return }
        pc.offer(for: mediaConstraints) { [weak self] sdp, _ in
            guard let self = self, let sdp = sdp else { return }
            pc.setLocalDescription(sdp, completionHandler: { _ in })
            self.hub?.sendWebRTCSignal(kind: "webrtc_offer", payload: ["sdp": sdp.sdp])
        }
    }

    func endCall() {
        peerConnection?.close()
        peerConnection = nil
    }

    private func setupPeerConnection() {
        let config = RTCConfiguration()
        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        // ^ Public, free Google STUN server — only used to discover NAT-traversal
        // candidates; no call data or audio ever passes through it. Fine to keep local-only
        // on the same hotspot, but harmless to leave in for when devices aren't on one LAN.

        peerConnection = factory.peerConnection(with: config, constraints: mediaConstraints, delegate: self)

        let audioSource = factory.audioSource(with: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil))
        let audioTrack = factory.audioTrack(with: audioSource, trackId: "simhub_audio0")
        localAudioTrack = audioTrack
        peerConnection?.add(audioTrack, streamIds: ["simhub_stream0"])
    }

    private func handleSignal(kind: String, json: [String: Any]) {
        switch kind {
        case "webrtc_offer":
            setupPeerConnection()
            guard let sdpString = json["sdp"] as? String else { return }
            let remoteSdp = RTCSessionDescription(type: .offer, sdp: sdpString)
            peerConnection?.setRemoteDescription(remoteSdp) { [weak self] _ in
                guard let self = self, let pc = self.peerConnection else { return }
                pc.answer(for: self.mediaConstraints) { sdp, _ in
                    guard let sdp = sdp else { return }
                    pc.setLocalDescription(sdp, completionHandler: { _ in })
                    self.hub?.sendWebRTCSignal(kind: "webrtc_answer", payload: ["sdp": sdp.sdp])
                }
            }

        case "webrtc_answer":
            guard let sdpString = json["sdp"] as? String else { return }
            let remoteSdp = RTCSessionDescription(type: .answer, sdp: sdpString)
            peerConnection?.setRemoteDescription(remoteSdp, completionHandler: { _ in })

        case "webrtc_ice":
            guard let sdpMid = json["sdpMid"] as? String,
                  let sdpMLineIndex = json["sdpMLineIndex"] as? Int32,
                  let candidate = json["candidate"] as? String else { return }
            let iceCandidate = RTCIceCandidate(sdp: candidate, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
            peerConnection?.add(iceCandidate)

        default:
            break
        }
    }
}

extension WebRTCClient: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        hub?.sendWebRTCSignal(kind: "webrtc_ice", payload: [
            "candidate": candidate.sdp,
            "sdpMid": candidate.sdpMid ?? "",
            "sdpMLineIndex": candidate.sdpMLineIndex
        ])
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}
}
