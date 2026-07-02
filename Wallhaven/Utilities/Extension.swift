import OSLog
import SwiftData
import SwiftUI

// MARK: - Hex Color

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - Card Style

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// MARK: - Haptic Feedback

func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
    UIImpactFeedbackGenerator(style: style).impactOccurred()
}

func notificationFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
    UINotificationFeedbackGenerator().notificationOccurred(type)
}

// MARK: - SwiftData Helpers

extension ModelContext {
    func saveWithLog() {
        do {
            try save()
        } catch {
            os_log(.error, "ModelContext save failed: %@", error.localizedDescription)
        }
    }

    /// Delete a FavoriteWallpaper matching the given predicate, deferred to next run-loop
    /// to avoid SwiftData mutation during context-menu dismiss.
    func deferredDelete(where predicate: Predicate<FavoriteWallpaper>, then completion: (() -> Void)? = nil) {
        DispatchQueue.main.async { [self] in
            let descriptor = FetchDescriptor<FavoriteWallpaper>(predicate: predicate)
            if let item = try? fetch(descriptor).first {
                delete(item)
                saveWithLog()
            }
            completion?()
        }
    }
}

// MARK: - Appearance

/// Apply the saved appearance preference to every connected window scene.
/// Loops all scenes (not just `.first`) so iPad multitasking windows are covered,
/// and is safe to call at launch from `ContentView.task`.
func applyAppAppearance(_ value: Int) {
    let style: UIUserInterfaceStyle = value == 1 ? .dark : value == 2 ? .light : .unspecified
    for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
        scene.windows.forEach { $0.overrideUserInterfaceStyle = style }
    }
}
