package com.srk.aichat.data

import android.content.Context
import android.util.Log
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException

@Database(entities = [MessageEntity::class], version = 1, exportSchema = false)
abstract class ChatDatabase : RoomDatabase() {
    abstract fun messageDao(): MessageDao
    
    companion object {
        private const val TAG = "ChatDatabase"
        private const val DATABASE_NAME = "chat_database"
        
        @Volatile
        private var INSTANCE: ChatDatabase? = null
        
        fun getDatabase(context: Context): ChatDatabase {
            return INSTANCE ?: synchronized(this) {
                try {
                    Log.d(TAG, "Creating database instance")
                    val instance = Room.databaseBuilder(
                        context.applicationContext,
                        ChatDatabase::class.java,
                        DATABASE_NAME
                    )
                    .fallbackToDestructiveMigration()
                    .addCallback(object : RoomDatabase.Callback() {
                        override fun onOpen(db: SupportSQLiteDatabase) {
                            super.onOpen(db)
                            CoroutineScope(Dispatchers.IO).launch {
                                try {
                                    backupDatabase(context)
                                } catch (e: Exception) {
                                    Log.e(TAG, "Failed to create backup", e)
                                }
                            }
                        }
                    })
                    .build()
                    INSTANCE = instance
                    instance
                } catch (e: Exception) {
                    Log.e(TAG, "Error creating database", e)
                    throw e
                }
            }
        }
        
        private fun backupDatabase(context: Context) {
            try {
                val dbFile = context.getDatabasePath(DATABASE_NAME)
                if (dbFile.exists()) {
                    val backupDir = File(context.filesDir, "database_backups")
                    if (!backupDir.exists()) {
                        backupDir.mkdirs()
                    }
                    
                    val backupFile = File(backupDir, "$DATABASE_NAME.backup")
                    
                    FileInputStream(dbFile).use { input ->
                        FileOutputStream(backupFile).use { output ->
                            input.copyTo(output)
                        }
                    }
                    
                    Log.d(TAG, "Database backup created successfully at ${backupFile.absolutePath}")
                }
            } catch (e: IOException) {
                Log.e(TAG, "Error backing up database", e)
            }
        }
        
        fun restoreFromBackup(context: Context): Boolean {
            try {
                val dbFile = context.getDatabasePath(DATABASE_NAME)
                val backupDir = File(context.filesDir, "database_backups")
                val backupFile = File(backupDir, "$DATABASE_NAME.backup")
                
                if (backupFile.exists()) {
                    INSTANCE?.close()
                    INSTANCE = null
                    
                    FileInputStream(backupFile).use { input ->
                        FileOutputStream(dbFile).use { output ->
                            input.copyTo(output)
                        }
                    }
                    
                    Log.d(TAG, "Database restored from backup successfully")
                    return true
                }
            } catch (e: IOException) {
                Log.e(TAG, "Error restoring database from backup", e)
            }
            
            return false
        }
    }
} 