import Foundation
import Combine

final class CaffeinateController: ObservableObject {
    @Published var isActive = false
    @Published var showCustomTimer = false
    @Published var remainingTime: TimeInterval = 0
    
    private var process: Process?
    private var timer: Timer?
    private var countdownTimer: Timer?
    private var timerEndDate: Date?

    func start() {
        guard !isActive else { return }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        process.arguments = ["-dimsu"]

        do {
            try process.run()
            self.process = process
            isActive = true
        } catch {
            print("Failed to start caffeinate:", error)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        timerEndDate = nil
        remainingTime = 0

        process?.terminate()
        process = nil
        isActive = false
    }

    func startTimer(minutes: Int) {
        guard isActive else { return }

        timer?.invalidate()
        countdownTimer?.invalidate()
        
        let duration = TimeInterval(minutes * 60)
        timerEndDate = Date().addingTimeInterval(duration)
        remainingTime = duration
        
        timer = Timer.scheduledTimer(
            withTimeInterval: duration,
            repeats: false
        ) { _ in
            DispatchQueue.main.async {
                self.stop()
            }
        }
        
        // Update countdown every second
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let endDate = self.timerEndDate else { return }
            let remaining = max(0, endDate.timeIntervalSinceNow)
            DispatchQueue.main.async {
                self.remainingTime = remaining
                if remaining <= 0 {
                    self.countdownTimer?.invalidate()
                }
            }
        }
    }
    
    var formattedRemainingTime: String {
        guard remainingTime > 0 else { return "No timer" }
        let hours = Int(remainingTime) / 3600
        let minutes = (Int(remainingTime) % 3600) / 60
        let seconds = Int(remainingTime) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
