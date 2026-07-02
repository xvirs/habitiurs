package com.habitiurs.app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

/** Provee las filas del widget de lista a partir del JSON exportado por la app. */
class HabitListRemoteViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        HabitListRemoteViewsFactory(applicationContext)
}

class HabitListRemoteViewsFactory(
    private val context: Context,
) : RemoteViewsService.RemoteViewsFactory {

    private var items: JSONArray = JSONArray()

    override fun onCreate() {}

    override fun onDataSetChanged() {
        val prefs = HomeWidgetPlugin.getData(context)
        val raw = prefs.getString("today_habits", "[]") ?: "[]"
        items = try {
            JSONArray(raw)
        } catch (e: Exception) {
            JSONArray()
        }
    }

    override fun onDestroy() {
        items = JSONArray()
    }

    override fun getCount(): Int = items.length()

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.habit_list_item)
        try {
            val item = items.getJSONObject(position)
            val id = item.getInt("id")
            val name = item.getString("name")
            val color = item.optInt("color", 0xFF1565C0.toInt())
            val status = item.optInt("status", 0) // 0=pending 1=completed 2=skipped

            views.setTextViewText(R.id.item_name, name)
            // Punto del color del hábito.
            views.setInt(R.id.item_dot, "setColorFilter", color)
            // Check según estado.
            views.setImageViewResource(
                R.id.item_check,
                if (status == 1) R.drawable.ic_check_done else R.drawable.ic_check_todo,
            )
            // Color del nombre adaptado al tema; atenuado si está completado.
            views.setInt(
                R.id.item_name,
                "setTextColor",
                context.getColor(
                    if (status == 1) R.color.w_on_surface_var else R.color.w_on_surface,
                ),
            )
            // Feedback: fondo sutil en las filas completadas (0 = sin fondo).
            views.setInt(
                R.id.item_root,
                "setBackgroundResource",
                if (status == 1) R.drawable.widget_row_done_bg else 0,
            )

            // Click en la fila → marca/desmarca (rellena la URI del template).
            val fillIn = Intent().apply {
                data = Uri.parse("habitiurs://toggle?id=$id")
            }
            views.setOnClickFillInIntent(R.id.item_root, fillIn)
        } catch (e: Exception) {
            views.setTextViewText(R.id.item_name, "—")
        }
        return views
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1

    // IDs estables (el id real del hábito) para que la ListView conserve las
    // filas al refrescar en vez de recrearlas → evita el parpadeo.
    override fun getItemId(position: Int): Long = try {
        items.getJSONObject(position).getInt("id").toLong()
    } catch (e: Exception) {
        position.toLong()
    }

    override fun hasStableIds(): Boolean = true
}
