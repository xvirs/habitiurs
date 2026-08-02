package com.habitiurs.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

/**
 * Widget "Pendientes": próximas misiones por urgencia (vencidas→hoy→próximas)
 * más un acceso rápido a crear una nueva. Al tocarlo abre la app.
 */
class MissionsWidgetProvider : HomeWidgetProvider() {

    private val rowIds =
        intArrayOf(R.id.mis_row0, R.id.mis_row1, R.id.mis_row2, R.id.mis_row3)
    private val dotIds =
        intArrayOf(R.id.mis_dot0, R.id.mis_dot1, R.id.mis_dot2, R.id.mis_dot3)
    private val titleIds =
        intArrayOf(R.id.mis_title0, R.id.mis_title1, R.id.mis_title2, R.id.mis_title3)
    private val dueIds =
        intArrayOf(R.id.mis_due0, R.id.mis_due1, R.id.mis_due2, R.id.mis_due3)

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val pending = widgetData.getInt("mission_pending", 0)
        val items: JSONArray = try {
            JSONArray(widgetData.getString("mission_items", "[]") ?: "[]")
        } catch (e: Exception) {
            JSONArray()
        }

        val overdue = context.getColor(R.color.w_overdue)
        val accent = context.getColor(R.color.w_accent)
        val muted = context.getColor(R.color.w_check_todo)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_missions).apply {
                setTextViewText(
                    R.id.mis_count,
                    if (pending == 1) "1 pendiente" else "$pending pendientes",
                )

                val count = items.length()
                if (count == 0) {
                    setViewVisibility(R.id.mis_empty, View.VISIBLE)
                    setViewVisibility(R.id.mis_rows, View.GONE)
                } else {
                    setViewVisibility(R.id.mis_empty, View.GONE)
                    setViewVisibility(R.id.mis_rows, View.VISIBLE)

                    for (i in rowIds.indices) {
                        if (i < count) {
                            val o = items.getJSONObject(i)
                            val urgency = o.optInt("urgency", 3)
                            val color = when (urgency) {
                                0 -> overdue
                                1 -> accent
                                else -> muted
                            }
                            setViewVisibility(rowIds[i], View.VISIBLE)
                            setTextViewText(titleIds[i], o.optString("title", ""))
                            setTextViewText(dueIds[i], o.optString("due", ""))
                            setTextColor(dueIds[i], color)
                            setInt(dotIds[i], "setColorFilter", color)
                        } else {
                            setViewVisibility(rowIds[i], View.GONE)
                        }
                    }
                }

                setOnClickPendingIntent(
                    R.id.mis_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
