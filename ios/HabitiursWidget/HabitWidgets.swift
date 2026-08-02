import SwiftUI
import WidgetKit

// MARK: - Timeline

struct HabitEntry: TimelineEntry {
    let date: Date
    let data: HabitData
}

struct HabitProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitEntry {
        HabitEntry(date: Date(), data: .empty)
    }
    func getSnapshot(in context: Context, completion: @escaping (HabitEntry) -> Void) {
        completion(HabitEntry(date: Date(), data: HabitData.load()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitEntry>) -> Void) {
        let entry = HabitEntry(date: Date(), data: HabitData.load())
        // La app refresca manualmente (WidgetCenter) al cambiar datos.
        completion(Timeline(entries: [entry], policy: .never))
    }
}

// MARK: - Helpers de estilo

struct ProgressBarView: View {
    let value: Double
    let scheme: ColorScheme
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(WColors.track(scheme))
                Capsule().fill(WColors.done(scheme))
                    .frame(width: geo.size.width * min(max(value, 0), 1))
            }
        }
    }
}

struct CardBackground: ViewModifier {
    let scheme: ColorScheme
    func body(content: Content) -> some View {
        let bg =
            scheme == .dark
            ? Color(red: 0.086, green: 0.125, blue: 0.169)  // #16202B
            : Color.white
        if #available(iOS 17.0, *) {
            content.containerBackground(bg, for: .widget)
        } else {
            content.background(bg)
        }
    }
}

// MARK: - Resumen del día

struct SummaryEntryView: View {
    @Environment(\.colorScheme) var scheme
    var entry: HabitEntry

    var body: some View {
        let d = entry.data
        let progress = d.total == 0 ? 0 : Double(d.completed) / Double(d.total)
        HStack(spacing: 14) {
            Text("\(d.completed)/\(d.total)")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(WColors.accent(scheme))
            VStack(alignment: .leading, spacing: 3) {
                Text("HOY")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(.secondary)
                Text(d.total == 0 ? "sin hábitos hoy" : "completados")
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                ProgressBarView(value: progress, scheme: scheme).frame(height: 6)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .modifier(CardBackground(scheme: scheme))
    }
}

struct HabitSummaryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "HabitiursSummaryWidget", provider: HabitProvider()) { entry in
            SummaryEntryView(entry: entry)
        }
        .configurationDisplayName("Resumen del día")
        .description("Tu progreso de hábitos de hoy de un vistazo.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Lista de hoy

struct ListEntryView: View {
    @Environment(\.colorScheme) var scheme
    @Environment(\.widgetFamily) var family
    var entry: HabitEntry

    var maxRows: Int { family == .systemLarge ? 8 : 4 }

    var body: some View {
        let d = entry.data
        let progress = d.total == 0 ? 0 : Double(d.completed) / Double(d.total)
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("Hábitos de hoy")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
                Text("\(d.completed)/\(d.total)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(WColors.accent(scheme))
            }
            ProgressBarView(value: progress, scheme: scheme).frame(height: 5)

            if d.items.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("Sin hábitos para hoy 🎉")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(Array(d.items.prefix(maxRows))) { item in
                    habitRow(item)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(14)
        .modifier(CardBackground(scheme: scheme))
    }

    // Fila de un hábito. En iOS 17+ es un botón que dispara el App Intent y
    // marca sin abrir la app; en versiones previas es solo lectura.
    @ViewBuilder
    func habitRow(_ item: HabitItem) -> some View {
        if #available(iOS 17.0, *) {
            Button(intent: ToggleHabitIntent(id: item.id)) {
                rowContent(item)
            }
            .buttonStyle(.plain)
        } else {
            rowContent(item)
        }
    }

    @ViewBuilder
    func rowContent(_ item: HabitItem) -> some View {
        HStack(spacing: 10) {
            Circle().fill(colorFromARGB(item.color)).frame(width: 10, height: 10)
            Text(item.name)
                .font(.system(size: 14))
                .foregroundColor(item.status == 1 ? .secondary : .primary)
                .lineLimit(1)
            Spacer()
            Image(systemName: item.status == 1 ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 19))
                .foregroundColor(item.status == 1 ? WColors.done(scheme) : .secondary)
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
    }
}

struct HabitListWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "HabitiursListWidget", provider: HabitProvider()) { entry in
            ListEntryView(entry: entry)
        }
        .configurationDisplayName("Hábitos de hoy")
        .description("Mirá tus hábitos de hoy sin abrir la app.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Racha ("No rompas la cadena")

struct StreakEntry: TimelineEntry {
    let date: Date
    let data: StreakData
}

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), data: .empty)
    }
    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(StreakEntry(date: Date(), data: StreakData.load()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        completion(Timeline(entries: [StreakEntry(date: Date(), data: StreakData.load())], policy: .never))
    }
}

struct StreakEntryView: View {
    @Environment(\.colorScheme) var scheme
    var entry: StreakEntry

    var body: some View {
        let d = entry.data
        let risk = d.atRisk && d.current > 0
        VStack(spacing: 2) {
            if risk {
                Text("EN RIESGO")
                    .font(.system(size: 10, weight: .bold)).tracking(0.8)
                    .foregroundColor(WColors.warn(scheme))
            }
            Text("🔥").font(.system(size: 26))
            Text("\(d.current)")
                .font(.system(size: 40, weight: .heavy))
                .foregroundColor(risk ? WColors.warn(scheme) : .primary)
            Text(d.current == 1 ? "día de racha" : "días de racha")
                .font(.system(size: 12)).foregroundColor(.secondary)
            if risk {
                Text(
                    d.remaining == 1
                        ? "Te falta 1 hábito para mantenerla"
                        : "Te faltan \(d.remaining) hábitos para mantenerla"
                )
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(WColors.warn(scheme))
                .multilineTextAlignment(.center)
                .padding(.top, 6).padding(.horizontal, 8)
            } else {
                Text("Mejor: \(d.best) días")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary).padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(CardBackground(scheme: scheme))
    }
}

struct StreakWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "HabitiursStreakWidget", provider: StreakProvider()) { entry in
            StreakEntryView(entry: entry)
        }
        .configurationDisplayName("Racha")
        .description("Tu racha actual y aviso cuando está en riesgo.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Constancia (heatmap)

struct HeatEntry: TimelineEntry {
    let date: Date
    let data: HeatData
    let best: Int
}

struct HeatProvider: TimelineProvider {
    private func load() -> HeatEntry {
        let d = UserDefaults(suiteName: appGroupId)
        return HeatEntry(
            date: Date(), data: HeatData.load(),
            best: d?.object(forKey: "streak_best") as? Int ?? 0)
    }
    func placeholder(in context: Context) -> HeatEntry {
        HeatEntry(date: Date(), data: .empty, best: 0)
    }
    func getSnapshot(in context: Context, completion: @escaping (HeatEntry) -> Void) {
        completion(load())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<HeatEntry>) -> Void) {
        completion(Timeline(entries: [load()], policy: .never))
    }
}

struct HeatEntryView: View {
    @Environment(\.colorScheme) var scheme
    var entry: HeatEntry

    func cellColor(_ level: Int) -> Color {
        switch level {
        case 1: return Color(red: 0.184, green: 0.749, blue: 0.424).opacity(0.34)
        case 2: return Color(red: 0.184, green: 0.749, blue: 0.424).opacity(0.62)
        case 3: return WColors.done(scheme)
        case -1: return .clear
        default: return WColors.track(scheme)
        }
    }

    var body: some View {
        let d = entry.data
        let weeks = max(d.weeks, 1)
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("CONSTANCIA")
                    .font(.system(size: 11, weight: .bold)).tracking(0.6)
                    .foregroundColor(.secondary)
                Spacer()
                Text("últimas \(weeks) sem")
                    .font(.system(size: 11)).foregroundColor(.secondary)
            }
            GeometryReader { geo in
                let gap: CGFloat = 3
                let cell = min(
                    (geo.size.width - gap * CGFloat(weeks - 1)) / CGFloat(weeks),
                    (geo.size.height - gap * 6) / 7)
                HStack(spacing: gap) {
                    ForEach(0..<weeks, id: \.self) { col in
                        VStack(spacing: gap) {
                            ForEach(0..<7, id: \.self) { row in
                                let idx = col * 7 + row
                                let lvl = idx < d.levels.count ? d.levels[idx] : 0
                                RoundedRectangle(cornerRadius: 2, style: .continuous)
                                    .fill(cellColor(lvl))
                                    .frame(width: cell, height: cell)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            Text(entry.best > 0 ? "🔥 Mejor racha: \(entry.best) días" : "Empezá tu racha hoy")
                .font(.system(size: 11)).foregroundColor(.secondary)
        }
        .padding(14)
        .modifier(CardBackground(scheme: scheme))
    }
}

struct HeatmapWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "HabitiursHeatmapWidget", provider: HeatProvider()) { entry in
            HeatEntryView(entry: entry)
        }
        .configurationDisplayName("Constancia")
        .description("Mapa de tu constancia de los últimos meses.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Pendientes (misiones)

struct MissionsEntry: TimelineEntry {
    let date: Date
    let data: MissionsData
}

struct MissionsProvider: TimelineProvider {
    func placeholder(in context: Context) -> MissionsEntry {
        MissionsEntry(date: Date(), data: .empty)
    }
    func getSnapshot(in context: Context, completion: @escaping (MissionsEntry) -> Void) {
        completion(MissionsEntry(date: Date(), data: MissionsData.load()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<MissionsEntry>) -> Void) {
        completion(Timeline(entries: [MissionsEntry(date: Date(), data: MissionsData.load())], policy: .never))
    }
}

struct MissionsEntryView: View {
    @Environment(\.colorScheme) var scheme
    @Environment(\.widgetFamily) var family
    var entry: MissionsEntry

    var maxRows: Int { family == .systemLarge ? 7 : 3 }

    func dotColor(_ urgency: Int) -> Color {
        switch urgency {
        case 0: return WColors.overdue(scheme)
        case 1: return WColors.accent(scheme)
        default: return .secondary
        }
    }

    var body: some View {
        let d = entry.data
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("MISIONES")
                    .font(.system(size: 11, weight: .bold)).tracking(0.6)
                    .foregroundColor(.secondary)
                Spacer()
                Text(d.pending == 1 ? "1 pendiente" : "\(d.pending) pendientes")
                    .font(.system(size: 11)).foregroundColor(.secondary)
            }
            if d.items.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("Sin misiones pendientes 🎉")
                        .font(.system(size: 13)).foregroundColor(.secondary)
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(Array(d.items.prefix(maxRows))) { m in
                    HStack(spacing: 9) {
                        Circle().fill(dotColor(m.urgency)).frame(width: 8, height: 8)
                        Text(m.title)
                            .font(.system(size: 13)).foregroundColor(.primary).lineLimit(1)
                        Spacer()
                        if !m.due.isEmpty {
                            Text(m.due)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(dotColor(m.urgency))
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            Link(destination: URL(string: "habitiurs://newmission")!) {
                Text("＋ Nueva misión")
                    .font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 9)
                    .background(WColors.accent(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(14)
        .modifier(CardBackground(scheme: scheme))
    }
}

struct MissionsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "HabitiursMissionsWidget", provider: MissionsProvider()) { entry in
            MissionsEntryView(entry: entry)
        }
        .configurationDisplayName("Misiones")
        .description("Tus misiones más urgentes y crear una nueva.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
