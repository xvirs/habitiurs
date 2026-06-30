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
                }
                Spacer(minLength: 0)
            }
        }
        .padding(14)
        .modifier(CardBackground(scheme: scheme))
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
