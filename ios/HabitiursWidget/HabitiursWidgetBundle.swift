import SwiftUI
import WidgetKit

@main
struct HabitiursWidgetBundle: WidgetBundle {
    var body: some Widget {
        HabitSummaryWidget()
        HabitListWidget()
    }
}
