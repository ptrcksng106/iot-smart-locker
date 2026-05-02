import Foundation
import Combine

enum UserMode: String, CaseIterable {
    case courier = "Courier"
    case receiver = "Receiver"

    var icon: String {
        switch self {
        case .courier: return "shippingbox.fill"
        case .receiver: return "arrow.down.to.line.circle.fill"
        }
    }
}

final class UserModeManager: ObservableObject {
    static let shared = UserModeManager()

    private let userDefaultsKey = "user_mode"

    @Published var currentMode: UserMode {
        didSet {
            UserDefaults.standard.set(currentMode.rawValue, forKey: userDefaultsKey)
        }
    }

    private init() {
        if let savedMode = UserDefaults.standard.string(forKey: userDefaultsKey),
           let mode = UserMode(rawValue: savedMode) {
            self.currentMode = mode
        } else {
            self.currentMode = .courier
        }
    }

    func toggle() {
        currentMode = currentMode == .courier ? .receiver : .courier
    }
}
