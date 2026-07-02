import AppIntents
import Foundation
import WidgetKit

/// App Intent que marca/desmarca un hábito desde el widget SIN abrir la app
/// (iOS 17+). No toca la base de datos (el intent corre en el sandbox de la
/// extensión): actualiza el App Group para feedback inmediato y deja el cambio
/// en `pending_toggles`, que la app concilia con la BD al abrir.
@available(iOS 16.0, *)
struct ToggleHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Marcar hábito"
    static var isDiscoverable: Bool = false

    @Parameter(title: "Habit ID")
    var id: Int

    init() {}
    init(id: Int) { self.id = id }

    func perform() async throws -> some IntentResult {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let raw = defaults.string(forKey: "today_habits"),
              let data = raw.data(using: .utf8),
              var arr = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]]
        else {
            return .result()
        }

        // Alternar el estado del hábito tocado (1=hecho → 0; cualquier otro → 1).
        var newStatus = 1
        for i in arr.indices {
            if let hid = arr[i]["id"] as? Int, hid == id {
                let current = arr[i]["status"] as? Int ?? 0
                newStatus = current == 1 ? 0 : 1
                arr[i]["status"] = newStatus
            }
        }

        if let out = try? JSONSerialization.data(withJSONObject: arr),
           let outStr = String(data: out, encoding: .utf8) {
            defaults.set(outStr, forKey: "today_habits")
        }

        // Recalcular contadores para el resumen y el header.
        let completed = arr.filter { ($0["status"] as? Int) == 1 }.count
        let total = arr.count
        defaults.set(completed, forKey: "today_completed")
        defaults.set(total, forKey: "today_total")
        defaults.set("\(completed)/\(total)", forKey: "today_summary")

        // Registrar el cambio pendiente (JSON {id: status}) para que la app lo
        // persista en la BD la próxima vez que se abra.
        var pending: [String: Int] = [:]
        if let praw = defaults.string(forKey: "pending_toggles"),
           let pdata = praw.data(using: .utf8),
           let pobj = (try? JSONSerialization.jsonObject(with: pdata)) as? [String: Int] {
            pending = pobj
        }
        pending["\(id)"] = newStatus
        if let pout = try? JSONSerialization.data(withJSONObject: pending),
           let poutStr = String(data: pout, encoding: .utf8) {
            defaults.set(poutStr, forKey: "pending_toggles")
        }

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
