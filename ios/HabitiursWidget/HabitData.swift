import SwiftUI
import WidgetKit

let appGroupId = "group.com.habitiurs.app"

struct HabitItem: Identifiable {
    let id: Int
    let name: String
    let color: Int
    let icon: String
    let status: Int // 0 pendiente, 1 completado, 2 omitido
}

struct HabitData {
    let items: [HabitItem]
    let completed: Int
    let total: Int

    static let empty = HabitData(items: [], completed: 0, total: 0)

    static func load() -> HabitData {
        let defaults = UserDefaults(suiteName: appGroupId)
        let raw = defaults?.string(forKey: "today_habits") ?? "[]"
        var items: [HabitItem] = []
        if let data = raw.data(using: .utf8),
            let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        {
            items = arr.compactMap { d in
                guard let id = (d["id"] as? NSNumber)?.intValue,
                    let name = d["name"] as? String
                else { return nil }
                return HabitItem(
                    id: id,
                    name: name,
                    color: (d["color"] as? NSNumber)?.intValue ?? 0xFF15_65C0,
                    icon: (d["icon"] as? String) ?? "check",
                    status: (d["status"] as? NSNumber)?.intValue ?? 0
                )
            }
        }
        let total = defaults?.object(forKey: "today_total") as? Int ?? items.count
        let completed =
            defaults?.object(forKey: "today_completed") as? Int
            ?? items.filter { $0.status == 1 }.count
        return HabitData(items: items, completed: completed, total: total)
    }
}

/// Convierte un color ARGB (int de Flutter) a Color de SwiftUI.
func colorFromARGB(_ argb: Int) -> Color {
    let a = Double((argb >> 24) & 0xFF) / 255.0
    let r = Double((argb >> 16) & 0xFF) / 255.0
    let g = Double((argb >> 8) & 0xFF) / 255.0
    let b = Double(argb & 0xFF) / 255.0
    return Color(.sRGB, red: r, green: g, blue: b, opacity: a == 0 ? 1 : a)
}

/// Paleta alineada a la app (se adapta a claro/oscuro vía colorScheme).
enum WColors {
    static func accent(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.498, green: 0.702, blue: 1.0)  // #7FB3FF
            : Color(red: 0.082, green: 0.396, blue: 0.753)  // #1565C0
    }
    static func done(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.4, green: 0.733, blue: 0.416)  // #66BB6A
            : Color(red: 0.18, green: 0.49, blue: 0.196)  // #2E7D32
    }
    static func track(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.165, green: 0.196, blue: 0.235)  // #2A323C
            : Color(red: 0.894, green: 0.910, blue: 0.933)  // #E4E8EE
    }
}
