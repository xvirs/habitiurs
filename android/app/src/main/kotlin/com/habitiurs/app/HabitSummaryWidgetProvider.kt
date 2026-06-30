package com.habitiurs.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget de "Resumen del día": muestra el progreso de hábitos de hoy (ej. 3/5).
 * Solo lectura: al tocarlo, abre la app.
 */
class HabitSummaryWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.habit_summary_widget).apply {
                val summary = widgetData.getString("today_summary", "0/0") ?: "0/0"
                val total = widgetData.getInt("today_total", 0)

                setTextViewText(R.id.widget_summary, summary)
                setTextViewText(
                    R.id.widget_subtitle,
                    if (total == 0) "sin hábitos para hoy" else "hábitos de hoy",
                )

                // Tap en el widget → abre la app.
                val launchIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                )
                setOnClickPendingIntent(R.id.widget_root, launchIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
