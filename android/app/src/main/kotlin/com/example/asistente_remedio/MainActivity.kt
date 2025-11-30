package com.example.asistente_remedio

import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onStart() {
        super.onStart()
        Log.d("MainActivity", "🔔 Verificando estado de notificaciones...")
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channels = notificationManager.notificationChannels
            Log.d("MainActivity", "📱 Android ${Build.VERSION.SDK_INT} - Canales existentes: ${channels.size}")
            for (channel in channels) {
                Log.d("MainActivity", "   - ${channel.id}: ${channel.name} (importancia: ${channel.importance})")
            }
        }
    }
}
