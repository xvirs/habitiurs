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
    static func warn(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 1.0, green: 0.718, blue: 0.302)  // #FFB74D
            : Color(red: 0.909, green: 0.349, blue: 0.047)  // #E8590C
    }
    static func overdue(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.937, green: 0.325, blue: 0.314)  // #EF5350
            : Color(red: 0.827, green: 0.184, blue: 0.184)  // #D32F2F
    }
}

// MARK: - Datos de los widgets derivados (racha, heatmap, misiones)

/// Racha actual + estado "en riesgo" (hoy con hábitos sin completar).
struct StreakData {
    let current: Int
    let best: Int
    let completedToday: Int
    let totalToday: Int

    var atRisk: Bool { totalToday > 0 && completedToday < totalToday }
    var remaining: Int { max(0, totalToday - completedToday) }

    static let empty = StreakData(current: 0, best: 0, completedToday: 0, totalToday: 0)

    static func load() -> StreakData {
        let d = UserDefaults(suiteName: appGroupId)
        return StreakData(
            current: d?.object(forKey: "streak_current") as? Int ?? 0,
            best: d?.object(forKey: "streak_best") as? Int ?? 0,
            completedToday: d?.object(forKey: "today_completed") as? Int ?? 0,
            totalToday: d?.object(forKey: "today_total") as? Int ?? 0
        )
    }
}

/// Heatmap de constancia: niveles alineados por semana (7 filas × weeks columnas).
struct HeatData {
    let weeks: Int
    let levels: [Int]  // largo weeks*7; -1 = día futuro (celda vacía)

    static let empty = HeatData(weeks: 0, levels: [])

    static func load() -> HeatData {
        let d = UserDefaults(suiteName: appGroupId)
        guard let raw = d?.string(forKey: "heat_data"),
            let data = raw.data(using: .utf8),
            let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return .empty }
        let weeks = (obj["weeks"] as? NSNumber)?.intValue ?? 0
        let levels = (obj["levels"] as? [NSNumber])?.map { $0.intValue } ?? []
        return HeatData(weeks: weeks, levels: levels)
    }
}

/// Misión urgente para el widget "Pendientes".
struct MissionItem: Identifiable {
    let id = UUID()
    let title: String
    let urgency: Int  // 0 vencida, 1 hoy, 2 próxima, 3 sin fecha
    let due: String
}

struct MissionsData {
    let items: [MissionItem]
    let pending: Int

    static let empty = MissionsData(items: [], pending: 0)

    static func load() -> MissionsData {
        let d = UserDefaults(suiteName: appGroupId)
        let pending = d?.object(forKey: "mission_pending") as? Int ?? 0
        var items: [MissionItem] = []
        if let raw = d?.string(forKey: "mission_items"),
            let data = raw.data(using: .utf8),
            let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        {
            items = arr.map { o in
                MissionItem(
                    title: o["title"] as? String ?? "",
                    urgency: (o["urgency"] as? NSNumber)?.intValue ?? 3,
                    due: o["due"] as? String ?? ""
                )
            }
        }
        return MissionsData(items: items, pending: pending)
    }
}
