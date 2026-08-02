package com.habitiurs.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget "No rompas la cadena" (2x1). La imagen la rinde Flutter con el look de
 * la maqueta; acá solo se muestra y se hace clickeable para abrir la app.
 */
class StreakWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val path = widgetData.getString("img_racha", null)
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_image).apply {
                if (path != null) {
                    BitmapFactory.decodeFile(path)?.let {
                        setImageViewBitmap(R.id.widget_image, it)
                    }
                }
                setOnClickPendingIntent(
                    R.id.widget_image,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
