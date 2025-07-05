package com.example.habitiurs

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Paint
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import androidx.annotation.RequiresApi
import java.time.LocalDate
import java.time.format.DateTimeFormatter

/**
 * RemoteViewsService que proporciona los datos para la ListView del widget.
 */
class WidgetListViewService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        Log.d("WidgetListViewService", "onGetViewFactory: Creando WidgetListViewFactory.")
        return WidgetListViewFactory(this.applicationContext, intent)
    }
}

/**
 * Implementación de RemoteViewsFactory para poblar la ListView.
 */
class WidgetListViewFactory(private val context: Context, intent: Intent) :
    RemoteViewsService.RemoteViewsFactory {

    private val appWidgetId: Int = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
    private var habits: List<Habit> = emptyList()
    private lateinit var dbHelper: WidgetDatabaseHelper
    private val TAG = "WidgetListViewFactory"

    override fun onCreate() {
        Log.d(TAG, "onCreate: Inicializando WidgetListViewFactory para widgetId: $appWidgetId")
        dbHelper = WidgetDatabaseHelper(context)
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onDataSetChanged() {
        Log.d(TAG, "onDataSetChanged: Actualizando datos para widgetId: $appWidgetId")
        
        val db = dbHelper.readableDatabase
        val today = LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE)
        Log.d(TAG, "onDataSetChanged - Fecha de hoy: $today")
        
        habits = try {
            val loadedHabits = dbHelper.getDailyHabitsWithStatus(db, today)
            Log.d(TAG, "Hábitos cargados: ${loadedHabits.size}")
            for (habit in loadedHabits) {
                Log.d(TAG, "Hábito: ID=${habit.id}, Nombre='${habit.name}', Estado=${habit.status}")
            }
            loadedHabits
        } catch (e: Exception) {
            Log.e(TAG, "Error al cargar hábitos: ${e.message}", e)
            emptyList()
        } finally {
            db.close()
        }
    }

    override fun onDestroy() {
        Log.d(TAG, "onDestroy: Cerrando WidgetListViewFactory para widgetId: $appWidgetId")
        dbHelper.close()
    }

    override fun getCount(): Int {
        Log.d(TAG, "getCount: ${habits.size}")
        return habits.size
    }

    @RequiresApi(Build.VERSION_CODES.M)
override fun getViewAt(position: Int): RemoteViews {
    if (position < 0 || position >= habits.size) {
        Log.w(TAG, "❌ getViewAt: Posición inválida ($position), total: ${habits.size}")
        return RemoteViews(context.packageName, R.layout.widget_habit_item)
    }

    val habit = habits[position]
    val views = RemoteViews(context.packageName, R.layout.widget_habit_item)
    
    Log.d(TAG, "🎨 getViewAt($position): Renderizando '${habit.name}' - ${habit.status}")

    // Configurar texto del hábito
    views.setTextViewText(R.id.habit_name, habit.name)
    views.setTextColor(R.id.habit_name, Color.WHITE)

    // Configurar icono y estilo según estado
    when (habit.status) {
        HabitStatus.PENDING -> {
            views.setImageViewResource(R.id.habit_status_icon, R.drawable.ic_add)
            views.setInt(R.id.habit_name, "setPaintFlags", 0)
        }
        HabitStatus.COMPLETED -> {
            views.setImageViewResource(R.id.habit_status_icon, R.drawable.ic_check)
            views.setInt(R.id.habit_name, "setPaintFlags", Paint.STRIKE_THRU_TEXT_FLAG)
        }
        HabitStatus.SKIPPED -> {
            views.setImageViewResource(R.id.habit_status_icon, R.drawable.ic_close)
            views.setInt(R.id.habit_name, "setPaintFlags", Paint.STRIKE_THRU_TEXT_FLAG)
        }
    }

    // ⚡ NUEVA CONFIGURACIÓN: fillInIntent más directo usando solo extras
    val fillInIntent = Intent().apply {
        // Método principal: Usar extras directamente
        putExtra(HabitiursWidget.EXTRA_HABIT_ID, habit.id)
        putExtra(HabitiursWidget.EXTRA_CURRENT_STATUS, habit.status.ordinal)
        
        // Método backup: URI también
        data = Uri.parse("habitiurs://widget_action/?habit_id=${habit.id}&current_status=${habit.status.ordinal}")
    }
    
    // Aplicar fillInIntent al contenedor clickeable
    views.setOnClickFillInIntent(R.id.habit_item_container, fillInIntent)
    
    Log.d(TAG, "🎯 fillInIntent configurado para hábito ${habit.id}")
    Log.d(TAG, "🎯 Extras: habitId=${habit.id}, status=${habit.status.ordinal}")
    Log.d(TAG, "🎯 URI: ${fillInIntent.data}")

    return views
}

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = habits[position].id.toLong()

    override fun hasStableIds(): Boolean = true
}