package com.habitiurs.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

/**
 * Widget "Constancia": mapa de calor estilo GitHub de los últimos meses.
 * La grilla se dibuja como bitmap (Canvas) y se escala al tamaño del widget.
 * Solo lectura: al tocarlo abre la app.
 */
class HeatmapWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val raw = widgetData.getString("heat_data", null)
        val best = widgetData.getInt("streak_best", 0)
        val (weeks, bitmap) = buildBitmap(context, raw)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_heatmap).apply {
                if (bitmap != null) setImageViewBitmap(R.id.heat_img, bitmap)
                setTextViewText(R.id.heat_range, "últimas $weeks sem")
                setTextViewText(
                    R.id.heat_foot,
                    if (best > 0) "🔥 Mejor racha: $best días" else "Empezá tu racha hoy",
                )
                setOnClickPendingIntent(
                    R.id.heat_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun buildBitmap(context: Context, raw: String?): Pair<Int, Bitmap?> {
        if (raw.isNullOrEmpty()) return 0 to null
        return try {
            val obj = JSONObject(raw)
            val weeks = obj.optInt("weeks", 15)
            val arr = obj.getJSONArray("levels")
            val levels = IntArray(arr.length()) { arr.getInt(it) }

            val cell = 18
            val gap = 4
            val rows = 7
            val w = weeks * (cell + gap) - gap
            val h = rows * (cell + gap) - gap
            val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bmp)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG)
            val radius = cell * 0.28f

            val track = context.getColor(R.color.w_track)
            val done = context.getColor(R.color.w_done)
            val l1 = 0x552FBF6C.toInt()
            val l2 = 0x992FBF6C.toInt()

            for (col in 0 until weeks) {
                for (row in 0 until rows) {
                    val idx = col * rows + row
                    if (idx >= levels.size) continue
                    val level = levels[idx]
                    if (level < 0) continue // día futuro: celda vacía
                    paint.color = when (level) {
                        1 -> l1
                        2 -> l2
                        3 -> done
                        else -> track
                    }
                    val x = col * (cell + gap).toFloat()
                    val y = row * (cell + gap).toFloat()
                    canvas.drawRoundRect(
                        RectF(x, y, x + cell, y + cell),
                        radius, radius, paint,
                    )
                }
            }
            weeks to bmp
        } catch (e: Exception) {
            0 to null
        }
    }
}
