import SwiftUI

struct TimerCommands: Commands {
    @ObservedObject var controller: CaffeinateController

    var body: some Commands {
        CommandMenu("Timer") {
            Button("15 Minutes") {
                controller.startTimer(minutes: 15)
            }
            .disabled(!controller.isActive)

            Button("30 Minutes") {
                controller.startTimer(minutes: 30)
            }
            .disabled(!controller.isActive)

            Button("1 Hour") {
                controller.startTimer(minutes: 60)
            }
            .disabled(!controller.isActive)

            Divider()

            Button("Custom Timer...") {
                controller.showCustomTimer = true
            }
            .disabled(!controller.isActive)

            Divider()

            Button("Stop Timer") {
                controller.stop()
            }
            .disabled(!controller.isActive)
        }
    }
}
