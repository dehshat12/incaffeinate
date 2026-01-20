import SwiftUI

struct ContentView: View {
    @EnvironmentObject var controller: CaffeinateController
    @State private var showWarning = false
    @State private var warningAcknowledged = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: controller.isActive
                        ? [Color.black, Color.green.opacity(0.45)]
                        : [Color.black, Color.gray.opacity(0.25)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: controller.isActive)

                VStack {
                    Spacer(minLength: 24)

                    VStack(spacing: 8) {
                        Text("InCaffeinate")
                            .font(.system(size: min(32, geo.size.width * 0.08), weight: .bold))
                            .foregroundStyle(.white.opacity(0.9))

                        Text(controller.isActive ? "SYSTEM HELD AWAKE" : "SLEEP PERMITTED")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(controller.isActive ? .green : .gray)
                            .tracking(1.5)
                            .animation(.easeInOut(duration: 0.4), value: controller.isActive)
                    }

                    Spacer()

                    Button {
                        handleToggle()
                    } label: {
                        Circle()
                            .fill(controller.isActive ? Color.green : Color.gray)
                            .frame(
                                width: min(geo.size.width * 0.28, geo.size.height * 0.4),
                                height: min(geo.size.width * 0.28, geo.size.height * 0.4)
                            )
                            .overlay(
                                Image(systemName: controller.isActive ? "bolt.fill" : "moon.fill")
                                    .font(.system(size: geo.size.width * 0.1))
                                    .foregroundColor(.black)
                            )
                            .shadow(
                                color: controller.isActive ? .green.opacity(0.7) : .black,
                                radius: controller.isActive ? 20 : 8
                            )
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text(controller.isActive ? "Click to release control" : "Click to deny sleep")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))

                    Spacer(minLength: 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 360, minHeight: 260)

        // ───── Warning Alert ─────
        .alert(
            "WARNING",
            isPresented: $showWarning
        ) {
            Button("OK") {
                warningAcknowledged = true
                controller.start()
            }
        } message: {
            Text("Using this app, you should acknowledge the battery usage may get high.")
        }
        // ───── Custom Timer Sheet ─────
        .sheet(isPresented: $controller.showCustomTimer) {
            CustomTimerView(controller: controller)
        }
    }

    // MARK: - Logic

    func handleToggle() {
        if controller.isActive {
            controller.stop()
        } else {
            if warningAcknowledged {
                controller.start()
            } else {
                showWarning = true
            }
        }
    }
}
