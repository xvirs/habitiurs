package com.habitiurs.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundReceiver
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget "Hábitos de hoy": lista interactiva. Tocar una fila marca/desmarca
 * el hábito sin abrir la app (vía el callback de fondo de home_widget).
 *
 * Anti-parpadeo: el bind COMPLETO (layout + adapter + template) se hace una sola
 * vez por widget. En cada refresco posterior solo se actualiza el contador/barra
 * con partiallyUpdateAppWidget y se refrescan las filas con
 * notifyAppWidgetViewDataChanged, sin re-inflar el widget entero.
 */
class HabitListWidgetProvider : HomeWidgetProvider() {

    private fun statePrefs(context: Context): SharedPreferences =
        context.getSharedPreferences("habit_widget_state", Context.MODE_PRIVATE)

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val state = statePrefs(context)

        appWidgetIds.forEach { widgetId ->
            val summary = widgetData.getString("today_summary", "0/0") ?: "0/0"
            val total = widgetData.getInt("today_total", 0)
            val completed = widgetData.getInt("today_completed", 0)
            val alreadyBound = state.getBoolean("bound_$widgetId", false)

            if (!alreadyBound) {
                // Primer bind: layout completo con adapter, empty view, template y
                // click del header. Esto es lo "caro" y solo ocurre una vez.
                val views = RemoteViews(context.packageName, R.layout.habit_list_widget)
                views.setTextViewText(R.id.widget_list_count, summary)
                views.setProgressBar(
                    R.id.widget_list_progress,
                    if (total == 0) 1 else total,
                    completed,
                    false,
                )

                val serviceIntent = Intent(context, HabitListRemoteViewsService::class.java).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                    data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
                }
                views.setRemoteAdapter(R.id.widget_list, serviceIntent)
                views.setEmptyView(R.id.widget_list, R.id.widget_empty)

                val toggleIntent = Intent(context, HomeWidgetBackgroundReceiver::class.java).apply {
                    action = "es.antonborri.home_widget.action.BACKGROUND"
                }
                val template = PendingIntent.getBroadcast(
                    context,
                    widgetId,
                    toggleIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
                )
                views.setPendingIntentTemplate(R.id.widget_list, template)

                views.setOnClickPendingIntent(
                    R.id.widget_header,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )

                appWidgetManager.updateAppWidget(widgetId, views)
                appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.widget_list)
                state.edit().putBoolean("bound_$widgetId", true).apply()
            } else {
                // Refresco ligero: solo contador/barra + refrescar filas, sin
                // re-inflar el widget → sin parpadeo.
                val views = RemoteViews(context.packageName, R.layout.habit_list_widget)
                views.setTextViewText(R.id.widget_list_count, summary)
                views.setProgressBar(
                    R.id.widget_list_progress,
                    if (total == 0) 1 else total,
                    completed,
                    false,
                )
                appWidgetManager.partiallyUpdateAppWidget(widgetId, views)
                appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.widget_list)
            }
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        val editor = statePrefs(context).edit()
        appWidgetIds.forEach { editor.remove("bound_$it") }
        editor.apply()
        super.onDeleted(context, appWidgetIds)
    }
}
