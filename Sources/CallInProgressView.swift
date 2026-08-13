import SwiftUI

struct CallInProgressView: View {
    let number: String
    @State private var muted = false
    @State private var speakerOn = false
    @State private var seconds = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var onEnd: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 8) {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .overlay(Image(systemName: "person.fill").font(.system(size: 40)).foregroundColor(.blue))
                Text(number).font(.title2).bold()
                Text(formattedTime).foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 40) {
                CallControlButton(icon: muted ? "mic.slash.fill" : "mic.fill", active: muted) {
                    muted.toggle()
                }
                CallControlButton(icon: speakerOn ? "speaker.wave.3.fill" : "speaker.fill", active: speakerOn) {
                    speakerOn.toggle()
                }
            }

            Button {
                onEnd()
            } label: {
                Image(systemName: "phone.down.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .frame(width: 72, height: 72)
                    .background(Circle().fill(Color.red))
            }
            .padding(.bottom, 40)
        }
        .onReceive(timer) { _ in seconds += 1 }
    }

    private var formattedTime: String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

private struct CallControlButton: View {
    let icon: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(active ? .white : .primary)
                .frame(width: 60, height: 60)
                .background(Circle().fill(active ? Color.blue : Color(.secondarySystemBackground)))
        }
    }
}
