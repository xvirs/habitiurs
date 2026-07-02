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
 * Se re-aplica el widget completo en cada update. La lista usa IDs estables
 * (ver HabitListRemoteViewsService) para que la ListView conserve las filas al
 * refrescar en vez de recrearlas, minimizando el parpadeo. El intent del
 * adapter es idéntico en cada update (mismo widgetId) para que Android reuse el
 * adapter y no lo recree.
 */
class HabitListWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.habit_list_widget)
            views.setTextViewText(
                R.id.widget_list_count,
                widgetData.getString("today_summary", "0/0") ?: "0/0",
            )
            val total = widgetData.getInt("today_total", 0)
            val completed = widgetData.getInt("today_completed", 0)
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
        }
    }
}
