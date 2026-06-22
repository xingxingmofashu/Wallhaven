import OSLog
import SwiftData

extension ModelContext {
    func saveWithLog() {
        do {
            try save()
        } catch {
            os_log(.error, "ModelContext save failed: %@", error.localizedDescription)
        }
    }
}
