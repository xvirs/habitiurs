package com.habitiurs.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget "No rompas la cadena" (2x2): racha actual con estado "en riesgo".
 * En riesgo = hoy tiene hábitos programados sin completar; entonces cambia a
 * color de alerta y pide cerrar el día. Solo lectura: al tocarlo abre la app.
 */
class StreakWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val current = widgetData.getInt("streak_current", 0)
        val best = widgetData.getInt("streak_best", 0)
        val total = widgetData.getInt("today_total", 0)
        val completed = widgetData.getInt("today_completed", 0)
        val atRisk = total > 0 && completed < total

        val warn = context.getColor(R.color.w_warn)
        val ink = context.getColor(R.color.w_on_surface)
        val muted = context.getColor(R.color.w_on_surface_var)
        val faint = context.getColor(R.color.w_check_todo)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_streak).apply {
                setTextViewText(R.id.streak_num, current.toString())

                if (atRisk && current > 0) {
                    // En riesgo: 2 líneas cortas que entran en 2x1.
                    val left = total - completed
                    setTextColor(R.id.streak_num, warn)
                    setTextViewText(R.id.streak_unit, "EN RIESGO")
                    setTextColor(R.id.streak_unit, warn)
                    setTextViewText(
                        R.id.streak_sub,
                        if (left == 1) "Falta 1 hoy" else "Faltan $left hoy",
                    )
                    setTextColor(R.id.streak_sub, warn)
                } else {
                    setTextColor(R.id.streak_num, ink)
                    setTextViewText(
                        R.id.streak_unit,
                        if (current == 1) "día de racha" else "días de racha",
                    )
                    setTextColor(R.id.streak_unit, muted)
                    setTextViewText(R.id.streak_sub, "Mejor: $best días")
                    setTextColor(R.id.streak_sub, faint)
                }

                setOnClickPendingIntent(
                    R.id.streak_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
