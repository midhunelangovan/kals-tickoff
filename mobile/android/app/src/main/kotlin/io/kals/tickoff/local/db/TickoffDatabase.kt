package io.kals.tickoff.local.db

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.util.Log

class TickoffDatabase(context: Context) :
    SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {

    companion object {
        private const val TAG = "TickoffDatabase"
        const val DATABASE_NAME = "tickoff.db"
        const val DATABASE_VERSION = 4
    }

    override fun onCreate(db: SQLiteDatabase) {
        Log.i(TAG, "Creating database schema (version $DATABASE_VERSION)")
        migrateV1(db)
        migrateV2(db)
        migrateV3(db)
        migrateV4(db)
        Log.i(TAG, "Database schema created successfully")
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        Log.i(TAG, "Upgrading database from version $oldVersion to $newVersion")
        if (oldVersion < 2) migrateV2(db)
        if (oldVersion < 3) migrateV3(db)
        if (oldVersion < 4) migrateV4(db)
        Log.i(TAG, "Database upgrade complete")
    }

    override fun onConfigure(db: SQLiteDatabase) {
        super.onConfigure(db)
        db.setForeignKeyConstraintsEnabled(true)
    }

    /**
     * V1: Core habits and completions tables.
     * Mirrors: V1__create_habits_and_completions.sql
     */
    private fun migrateV1(db: SQLiteDatabase) {
        db.execSQL("""
            CREATE TABLE IF NOT EXISTS habits (
                id VARCHAR(36) PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                created_at TIMESTAMP NOT NULL,
                archived BOOLEAN NOT NULL DEFAULT 0
            )
        """.trimIndent())

        db.execSQL("""
            CREATE TABLE IF NOT EXISTS habit_completions (
                id VARCHAR(36) PRIMARY KEY,
                habit_id VARCHAR(36) NOT NULL,
                completion_date DATE NOT NULL,
                created_at TIMESTAMP NOT NULL,
                CONSTRAINT fk_habit_completions_habit FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE,
                CONSTRAINT uq_habit_completion_date UNIQUE (habit_id, completion_date)
            )
        """.trimIndent())

        db.execSQL("CREATE INDEX IF NOT EXISTS idx_habits_archived_created ON habits (archived, created_at DESC)")
        db.execSQL("CREATE INDEX IF NOT EXISTS idx_completions_habit_id ON habit_completions (habit_id)")
        db.execSQL("CREATE INDEX IF NOT EXISTS idx_completions_date ON habit_completions (completion_date)")
        db.execSQL("CREATE INDEX IF NOT EXISTS idx_completions_habit_date ON habit_completions (habit_id, completion_date)")
    }

    /**
     * V2: Add icon column to habits.
     * Mirrors: V2__add_icon_to_habits.sql
     */
    private fun migrateV2(db: SQLiteDatabase) {
        db.execSQL("ALTER TABLE habits ADD COLUMN icon VARCHAR(50) NOT NULL DEFAULT 'walking'")
    }

    /**
     * V3: Add categories table, category_id/description/color columns to habits.
     * Mirrors: V3__add_categories_and_habit_category_id.sql
     */
    private fun migrateV3(db: SQLiteDatabase) {
        db.execSQL("""
            CREATE TABLE IF NOT EXISTS categories (
                id VARCHAR(36) PRIMARY KEY,
                name VARCHAR(100) NOT NULL UNIQUE,
                created_at TIMESTAMP NOT NULL
            )
        """.trimIndent())

        db.execSQL("ALTER TABLE habits ADD COLUMN category_id VARCHAR(36) NULL REFERENCES categories(id) ON DELETE SET NULL")
        db.execSQL("ALTER TABLE habits ADD COLUMN description VARCHAR(255) NULL")
        db.execSQL("ALTER TABLE habits ADD COLUMN color VARCHAR(50) NULL")

        db.execSQL("CREATE INDEX IF NOT EXISTS idx_categories_name ON categories (name)")
        db.execSQL("CREATE INDEX IF NOT EXISTS idx_habits_category_id ON habits (category_id)")
    }

    /**
     * V4: Add sort_order to habits and create habit_notes table.
     */
    private fun migrateV4(db: SQLiteDatabase) {
        db.execSQL("ALTER TABLE habits ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0")

        db.execSQL("""
            CREATE TABLE IF NOT EXISTS habit_notes (
                id VARCHAR(36) PRIMARY KEY,
                habit_id VARCHAR(36) NOT NULL,
                note_date DATE NOT NULL,
                content TEXT NOT NULL,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL,
                CONSTRAINT fk_habit_notes_habit FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE,
                CONSTRAINT uq_habit_note_date UNIQUE (habit_id, note_date)
            )
        """.trimIndent())

        db.execSQL("CREATE INDEX IF NOT EXISTS idx_habits_sort_order ON habits (archived, sort_order ASC, created_at DESC)")
        db.execSQL("CREATE INDEX IF NOT EXISTS idx_notes_habit_id ON habit_notes (habit_id)")
        db.execSQL("CREATE INDEX IF NOT EXISTS idx_notes_date ON habit_notes (note_date)")
        db.execSQL("CREATE INDEX IF NOT EXISTS idx_notes_habit_date ON habit_notes (habit_id, note_date)")
    }
}
