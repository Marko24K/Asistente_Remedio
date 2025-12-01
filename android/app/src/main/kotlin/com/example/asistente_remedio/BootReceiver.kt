package com.example.asistente_remedio

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("BootReceiver", "🔔 BOOT_COMPLETED detectado - Rescheduleando notificaciones...")
            
            if (context != null) {
                try {
                    // Lanzar la app principal en background
                    val mainIntent = Intent(context, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        putExtra("boot_reschedule", true)
                    }
                    context.startActivity(mainIntent)
                    Log.d("BootReceiver", "✅ MainActivity lanzada para reschedule")
                } catch (e: Exception) {
                    Log.e("BootReceiver", "❌ Error lanzando MainActivity: ${e.message}")
                }
            }
        }
    }
}
