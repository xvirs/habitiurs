package com.habitiurs.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Widget "Resumen del día" (1x2): fecha + progreso de hábitos de hoy con barra.
 * Solo lectura: al tocarlo, abre la app.
 */
class HabitSummaryWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val dateLabel = SimpleDateFormat("EEE d", Locale("es", "ES"))
            .format(Date())
            .replaceFirstChar { it.uppercase() }

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.habit_summary_widget).apply {
                val summary = widgetData.getString("today_summary", "0/0") ?: "0/0"
                val total = widgetData.getInt("today_total", 0)
                val completed = widgetData.getInt("today_completed", 0)

                setTextViewText(R.id.widget_date, dateLabel)
                setTextViewText(R.id.widget_summary, summary)
                setTextViewText(
                    R.id.widget_subtitle,
                    if (total == 0) "sin hábitos hoy" else "completados",
                )
                setProgressBar(R.id.widget_progress, if (total == 0) 1 else total, completed, false)

                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
