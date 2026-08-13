import SwiftUI

struct KeypadView: View {
    @EnvironmentObject var hub: HubConnection
    @State private var enteredNumber: String = ""

    private let keys: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["*", "0", "#"]
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(enteredNumber.isEmpty ? " " : enteredNumber)
                .font(.system(size: 36, weight: .light))
                .frame(height: 44)
                .padding(.horizontal)

            VStack(spacing: 18) {
                ForEach(keys, id: \.self) { row in
                    HStack(spacing: 18) {
                        ForEach(row, id: \.self) { key in
                            KeyButton(label: key) {
                                enteredNumber.append(key)
                            }
                        }
                    }
                }
            }

            HStack {
                Spacer()

                Button {
                    guard !enteredNumber.isEmpty else { return }
                    WebRTCClient.shared.startAsCaller()
                    hub.dial(number: enteredNumber)
                } label: {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.white)
                        .frame(width: 72, height: 72)
                        .background(Circle().fill(Color.green))
                }
                .disabled(enteredNumber.isEmpty || hub.state != .paired)

                Spacer()

                if !enteredNumber.isEmpty {
                    Button {
                        enteredNumber.removeLast()
                    } label: {
                        Image(systemName: "delete.left")
                            .font(.system(size: 22))
                            .foregroundColor(.primary)
                    }
                    .frame(width: 60)
                } else {
                    Spacer().frame(width: 60)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }
}

private struct KeyButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 30))
                .frame(width: 72, height: 72)
                .background(Circle().fill(Color(.secondarySystemBackground)))
                .foregroundColor(.primary)
        }
    }
}
