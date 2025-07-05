package com.example.habitiurs

import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.LocalDateTime

// Representación simplificada del modelo de hábito para el widget
data class Habit(
    val id: Int,
    val name: String,
    val status: HabitStatus // Usamos nuestro enum de estado de hábito
)

enum class HabitStatus {
    PENDING,
    COMPLETED,
    SKIPPED
}

// Helper para la base de datos SQLite específica del widget
class WidgetDatabaseHelper(context: Context) :
    SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {

    companion object {
        private const val TAG = "WidgetDBHelper"
        private const val DATABASE_NAME = "habitiurs.db"
        private const val DATABASE_VERSION = 5

        // Nombres de tablas y columnas
        private const val TABLE_HABITS = "habits"
        private const val COLUMN_HABIT_ID = "id"
        private const val COLUMN_HABIT_NAME = "name"
        private const val COLUMN_HABIT_CREATED_AT = "created_at"
        private const val COLUMN_HABIT_IS_ACTIVE = "is_active"

        private const val TABLE_HABIT_ENTRIES = "habit_entries"
        private const val COLUMN_ENTRY_HABIT_ID = "habit_id"
        private const val COLUMN_ENTRY_DATE = "date"
        private const val COLUMN_ENTRY_STATUS = "status"
        private const val COLUMN_ENTRY_LAST_MODIFIED = "last_modified"
    }

    override fun onCreate(db: SQLiteDatabase) {
        Log.d(TAG, "onCreate: Called for database. Tables are expected to be created by Flutter app.")
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        Log.d(TAG, "onUpgrade: Migrating database from version $oldVersion to $newVersion")
        if (oldVersion < 4) {
            try {
                db.execSQL("ALTER TABLE $TABLE_HABIT_ENTRIES ADD COLUMN $COLUMN_ENTRY_LAST_MODIFIED TEXT;")
                Log.d(TAG, "onUpgrade: Added $COLUMN_ENTRY_LAST_MODIFIED column to $TABLE_HABIT_ENTRIES")
            } catch (e: Exception) {
                Log.e(TAG, "onUpgrade: Error adding column, might already exist or other issue.", e)
            }
        }
    }

    /**
     * Obtiene todos los hábitos activos para el día de hoy, junto con su estado.
     */
    fun getDailyHabitsWithStatus(db: SQLiteDatabase, date: String): List<Habit> {
        Log.d(TAG, "🔍 Consultando hábitos para la fecha: $date")
        val habits = mutableListOf<Habit>()
        
        // Primero verificar si hay hábitos en la tabla
        val countQuery = "SELECT COUNT(*) FROM $TABLE_HABITS WHERE $COLUMN_HABIT_IS_ACTIVE = 1"
        val countCursor = db.rawQuery(countQuery, null)
        countCursor.moveToFirst()
        val totalHabits = countCursor.getInt(0)
        countCursor.close()
        Log.d(TAG, "🔍 Total de hábitos activos en DB: $totalHabits")
        
        val query = """
            SELECT
                h.$COLUMN_HABIT_ID,
                h.$COLUMN_HABIT_NAME,
                COALESCE(he.$COLUMN_ENTRY_STATUS, ?) AS status_ordinal
            FROM $TABLE_HABITS AS h
            LEFT JOIN $TABLE_HABIT_ENTRIES AS he
                ON h.$COLUMN_HABIT_ID = he.$COLUMN_ENTRY_HABIT_ID AND he.$COLUMN_ENTRY_DATE = ?
            WHERE h.$COLUMN_HABIT_IS_ACTIVE = 1
            ORDER BY h.$COLUMN_HABIT_CREATED_AT DESC
        """.trimIndent()

        val cursor: Cursor = db.rawQuery(query, arrayOf(HabitStatus.PENDING.ordinal.toString(), date))

        cursor.use {
            val idColumnIndex = it.getColumnIndex(COLUMN_HABIT_ID)
            val nameColumnIndex = it.getColumnIndex(COLUMN_HABIT_NAME)
            val statusOrdinalColumnIndex = it.getColumnIndex("status_ordinal")

            if (idColumnIndex == -1 || nameColumnIndex == -1 || statusOrdinalColumnIndex == -1) {
                Log.e(TAG, "❌ Una o más columnas no encontradas en la consulta")
                return emptyList()
            }

            while (it.moveToNext()) {
                val id = it.getInt(idColumnIndex)
                val name = it.getString(nameColumnIndex)
                val statusOrdinal = it.getInt(statusOrdinalColumnIndex)
                val status = HabitStatus.values()[statusOrdinal]
                habits.add(Habit(id, name, status))
                Log.d(TAG, "✅ Hábito: ID=$id, Nombre='$name', Estado=$status")
            }
        }
        
        Log.d(TAG, "📊 Total de hábitos recuperados para widget: ${habits.size}")
        return habits
    }

    /**
     * Verifica si existe una entrada de hábito para una fecha específica.
     */
    fun getHabitEntry(db: SQLiteDatabase, habitId: Int, date: String): Boolean {
        val query = """
            SELECT 1 FROM $TABLE_HABIT_ENTRIES
            WHERE $COLUMN_ENTRY_HABIT_ID = ? AND $COLUMN_ENTRY_DATE = ?
            LIMIT 1
        """.trimIndent()
        
        val cursor = db.rawQuery(query, arrayOf(habitId.toString(), date))
        val exists = cursor.count > 0
        cursor.close()
        Log.d(TAG, "🔍 getHabitEntry: HabitId=$habitId, Date=$date, Exists=$exists")
        return exists
    }

    /**
     * Inserta una nueva entrada de hábito.
     */
    @RequiresApi(Build.VERSION_CODES.O)
    fun insertHabitEntry(db: SQLiteDatabase, habitId: Int, date: String, status: Int) {
        Log.d(TAG, "➕ insertHabitEntry: Creando entrada para hábito $habitId en $date con estado $status")
        
        val values = ContentValues().apply {
            put(COLUMN_ENTRY_HABIT_ID, habitId)
            put(COLUMN_ENTRY_DATE, date)
            put(COLUMN_ENTRY_STATUS, status)
            put(COLUMN_ENTRY_LAST_MODIFIED, LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME))
        }
        
        val result = db.insert(TABLE_HABIT_ENTRIES, null, values)
        
        if (result != -1L) {
            Log.d(TAG, "✅ insertHabitEntry: Entrada creada con ID $result")
        } else {
            Log.e(TAG, "❌ insertHabitEntry: Error al crear entrada")
        }
    }

    /**
     * Actualiza el estado de una entrada de hábito existente.
     */
    @RequiresApi(Build.VERSION_CODES.O)
    fun updateHabitEntry(db: SQLiteDatabase, habitId: Int, date: String, status: Int) {
        Log.d(TAG, "📝 updateHabitEntry: Actualizando hábito $habitId para $date con estado $status")
        
        val values = ContentValues().apply {
            put(COLUMN_ENTRY_STATUS, status)
            put(COLUMN_ENTRY_LAST_MODIFIED, LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME))
        }
        
        val rowsAffected = db.update(
            TABLE_HABIT_ENTRIES,
            values,
            "$COLUMN_ENTRY_HABIT_ID = ? AND $COLUMN_ENTRY_DATE = ?",
            arrayOf(habitId.toString(), date)
        )
        
        if (rowsAffected > 0) {
            Log.d(TAG, "✅ updateHabitEntry: $rowsAffected fila(s) actualizada(s)")
        } else {
            Log.e(TAG, "❌ updateHabitEntry: No se pudo actualizar - entrada no existe?")
        }
    }
}