package com.example.habitiurs

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.widget.RemoteViews
import android.util.Log
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.concurrent.Executors

class HabitiursWidget : AppWidgetProvider() {

    companion object {
        private const val TAG = "HabitiursWidget"
        const val ACTION_TOGGLE_HABIT_STATUS = "com.example.habitiurs.TOGGLE_HABIT_STATUS"
        const val ACTION_REFRESH_WIDGET = "com.example.habitiurs.ACTION_REFRESH_WIDGET"
        const val EXTRA_HABIT_ID = "habit_id"
        const val EXTRA_CURRENT_STATUS = "current_status"
    }

    private val executor = Executors.newSingleThreadExecutor()

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        Log.d(TAG, "🔄 onUpdate: Actualizando ${appWidgetIds.size} widgets.")
        for (appWidgetId in appWidgetIds) {
            updateAppWidgetViews(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        Log.d(TAG, "📨 onReceive: Acción recibida -> ${intent.action}")
        Log.d(TAG, "📨 onReceive: Intent data -> ${intent.data}")
        
        // Debug: Mostrar todos los extras del intent
        intent.extras?.let { bundle ->
            for (key in bundle.keySet()) {
                val value = bundle.get(key)
                Log.d(TAG, "📨 Intent Extra: $key = $value")
            }
        }

        when (intent.action) {
            ACTION_TOGGLE_HABIT_STATUS -> {
                handleToggleHabitStatus(context, intent)
            }
            ACTION_REFRESH_WIDGET -> {
                handleRefreshWidget(context)
            }
        }
    }

    private fun handleToggleHabitStatus(context: Context, intent: Intent) {
        Log.d(TAG, "🎯 handleToggleHabitStatus: Procesando toggle...")
        
        var habitId = -1
        var currentStatusOrdinal = -1

        // Método 1: Intentar obtener de URI data
        intent.data?.let { uri ->
            Log.d(TAG, "🎯 URI completa: $uri")
            Log.d(TAG, "🎯 URI scheme: ${uri.scheme}, host: ${uri.host}")
            
            if (uri.scheme == "habitiurs" && uri.host == "widget_action") {
                try {
                    habitId = uri.getQueryParameter(EXTRA_HABIT_ID)?.toInt() ?: -1
                    currentStatusOrdinal = uri.getQueryParameter(EXTRA_CURRENT_STATUS)?.toInt() ?: -1
                    Log.d(TAG, "🎯 Desde URI - habitId: $habitId, status: $currentStatusOrdinal")
                } catch (e: NumberFormatException) {
                    Log.e(TAG, "❌ Error parseando URI: ${e.message}")
                }
            }
        }

        // Método 2: Si URI falló, intentar obtener de extras
        if (habitId == -1 || currentStatusOrdinal == -1) {
            habitId = intent.getIntExtra(EXTRA_HABIT_ID, -1)
            currentStatusOrdinal = intent.getIntExtra(EXTRA_CURRENT_STATUS, -1)
            Log.d(TAG, "🎯 Desde Extras - habitId: $habitId, status: $currentStatusOrdinal")
        }

        if (habitId != -1 && currentStatusOrdinal != -1) {
            Log.d(TAG, "✅ Datos válidos recibidos: habitId=$habitId, currentStatus=$currentStatusOrdinal")
            
            executor.execute {
                try {
                    toggleHabitStatus(context, habitId, currentStatusOrdinal)
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Error en toggleHabitStatus: ${e.message}", e)
                }
            }
        } else {
            Log.e(TAG, "❌ Datos inválidos: habitId=$habitId, currentStatus=$currentStatusOrdinal")
        }
    }

    private fun toggleHabitStatus(context: Context, habitId: Int, currentStatusOrdinal: Int) {
        Log.d(TAG, "⚡ toggleHabitStatus: Iniciando para hábito $habitId")
        
        val dbHelper = WidgetDatabaseHelper(context)
        val db = dbHelper.writableDatabase

        try {
            val newStatus = when (currentStatusOrdinal) {
                HabitStatus.PENDING.ordinal -> HabitStatus.COMPLETED
                HabitStatus.COMPLETED.ordinal -> HabitStatus.PENDING
                HabitStatus.SKIPPED.ordinal -> HabitStatus.COMPLETED
                else -> HabitStatus.PENDING
            }
            
            Log.d(TAG, "⚡ Cambiando estado: ${HabitStatus.values()[currentStatusOrdinal]} -> $newStatus")

            val today = LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE)
            val existingEntry = dbHelper.getHabitEntry(db, habitId, today)
            
            if (existingEntry) {
                dbHelper.updateHabitEntry(db, habitId, today, newStatus.ordinal)
                Log.d(TAG, "✅ Entrada actualizada para hábito $habitId")
            } else {
                if (newStatus == HabitStatus.COMPLETED) {
                    dbHelper.insertHabitEntry(db, habitId, today, newStatus.ordinal)
                    Log.d(TAG, "✅ Nueva entrada creada para hábito $habitId")
                }
            }
            
            // Refrescar widget inmediatamente
            refreshAllWidgets(context)
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error en operación de base de datos: ${e.message}", e)
        } finally {
            db.close()
            dbHelper.close()
        }
    }

    private fun handleRefreshWidget(context: Context) {
        Log.d(TAG, "🔄 handleRefreshWidget: Refrescando todos los widgets...")
        refreshAllWidgets(context)
    }

    private fun refreshAllWidgets(context: Context) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(
            ComponentName(context, HabitiursWidget::class.java)
        )
        
        // Forzar actualización de datos
        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.habits_listview)
        Log.d(TAG, "🔄 notifyAppWidgetViewDataChanged enviado para ${appWidgetIds.size} widgets")
        
        // También actualizar las vistas
        for (appWidgetId in appWidgetIds) {
            updateAppWidgetViews(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        Log.d(TAG, "🗑️ onDeleted: ${appWidgetIds.size} widget(s) eliminados.")
    }

    override fun onEnabled(context: Context) {
        Log.d(TAG, "✨ onEnabled: Primera instancia de widget creada.")
    }

    override fun onDisabled(context: Context) {
        Log.d(TAG, "💤 onDisabled: Última instancia de widget eliminada.")
        executor.shutdown()
    }
}

internal fun updateAppWidgetViews(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int
) {
    Log.d("updateAppWidgetViews", "🎨 Configurando RemoteViews para widget: $appWidgetId")
    val views = RemoteViews(context.packageName, R.layout.habitiurs_widget)

    // Configurar RemoteAdapter para la ListView
    val serviceIntent = Intent(context, WidgetListViewService::class.java).apply {
        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        data = Uri.fromParts("content", "$appWidgetId", null)
    }
    views.setRemoteAdapter(R.id.habits_listview, serviceIntent)

    // PendingIntent para abrir la app al tocar el título
    val appIntent = Intent(context, MainActivity::class.java).apply {
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
    }
    val pendingAppIntent = PendingIntent.getActivity(
        context,
        0,
        appIntent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )
    views.setOnClickPendingIntent(R.id.widget_title, pendingAppIntent)

    // ⚡ ENFOQUE DIRECTO: Template intent sin URI, solo con la action
    val toggleTemplateIntent = Intent(context, HabitiursWidget::class.java).apply {
        action = HabitiursWidget.ACTION_TOGGLE_HABIT_STATUS
    }
    
    val pendingToggleTemplateIntent = PendingIntent.getBroadcast(
        context,
        appWidgetId,
        toggleTemplateIntent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
    )
    views.setPendingIntentTemplate(R.id.habits_listview, pendingToggleTemplateIntent)

    // PendingIntent para botón de refresh  
    val refreshIntent = Intent(context, HabitiursWidget::class.java).apply {
        action = HabitiursWidget.ACTION_REFRESH_WIDGET
    }
    val pendingRefreshIntent = PendingIntent.getBroadcast(
        context,
        appWidgetId + 1000,
        refreshIntent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )
    views.setOnClickPendingIntent(R.id.refresh_button, pendingRefreshIntent)

    views.setEmptyView(R.id.habits_listview, R.id.empty_view)

    appWidgetManager.updateAppWidget(appWidgetId, views)
    Log.d("updateAppWidgetViews", "✅ Widget $appWidgetId configurado correctamente")
}